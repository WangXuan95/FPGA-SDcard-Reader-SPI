// module  : sd_file_reader
// function: Specify a filename that the module will read out its contents
// Compatibility: CardType   : SDv1.1 , SDv2  and SDHCv2
//                FileSystem : FAT16 and FAT32

module sd_file_reader #(
    parameter FILE_NAME = "example.txt",  // file to read, ignore Upper and Lower Case
                                          // For example, if you want to read a file named HeLLo123.txt in the SD card,
                                          // the parameter here can be hello123.TXT, HELLO123.txt or HEllo123.Txt
                                          
    parameter SPI_CLK_DIV = 50            // SD spi_clk freq = clk freq/(2*SPI_CLK_DIV)
                                          // modify SPI_CLK_DIV to change the SPI speed
                                          // for example, when clk=50MHz, SPI_CLK_DIV=50,then spi_clk=50MHz/(2*50)=500kHz
                                          // 500kHz is a typical SPI speed for SDcard
                                          
)(
    input  logic clk, rst_n,
    // sdcard interface (spi)
    input  logic spi_miso,
    output logic spi_mosi, spi_clk, spi_cs_n,
    // status output
    output logic [1:0] sdcardtype,        // SDv1, SDv2, SDHCv2 or UNKNOWN
    output logic [1:0] filesystemtype,    // FAT16, FAT32 or UNKNOWN
    output logic [3:0] sdcardstate,       // show the sdcard initialize status
    output logic [2:0] fatstate,          // show the fat initialize status
    output logic file_found,              // 0=file not found, 1=file found
    // file content data output
    output logic outreq,                  // when outreq=1, a byte of file content is read out from outbyte
    output logic [7:0] outbyte            // a byte of file content
);

function automatic logic [7:0] toUpperCase(input [7:0] in);
    return (in>="a" && in<="z") ? in&8'b11011111 : in;
endfunction

localparam TARGET_FNAME_LEN = ($bits(FILE_NAME)/8);
wire  [$bits(FILE_NAME)-1:0] TARGET_FNAME = FILE_NAME;
logic [$bits(FILE_NAME)-1:0] TARGET_FNAME_UPPER;
always @ (*) begin
    for(int ii=0; ii<TARGET_FNAME_LEN; ii++)
        TARGET_FNAME_UPPER[ii*8+:8] = toUpperCase( TARGET_FNAME[ii*8+:8] );
end

initial file_found = 1'b0;

logic read_start     = 1'b0;
logic [31:0] read_sector_no = 0;
logic read_done;

logic rvalid;
logic [ 8:0] raddr;
logic [ 7:0] rdata;

logic is_boot_sector, is_dbr;
logic [31:0] dbr_sector_no;

logic [15:0] rootdir_itemcount;   // FAT16 only
logic [15:0] bytes_per_sector;
logic [ 7:0] sector_per_cluster;
logic [15:0] resv_sectors;
logic [ 7:0] number_of_fat;
logic [31:0] sectors_per_fat;
logic [31:0] root_cluster;

logic [31:0] rootdir_sector;      // FAT16 only
logic [15:0] rootdir_sectorcount; // FAT16 only

logic [31:0] curr_cluster = 0;    // current reading cluster number

logic [ 6:0] curr_cluster_fat_offset;
logic [24:0] curr_cluster_fat_no;
assign {curr_cluster_fat_no,curr_cluster_fat_offset} = curr_cluster;

logic [ 7:0] curr_cluster_fat_offset_fat16;
logic [23:0] curr_cluster_fat_no_fat16;
assign {curr_cluster_fat_no_fat16,curr_cluster_fat_offset_fat16} = curr_cluster;

logic [15:0] target_cluster_fat16 = 16'h0;
logic [31:0] target_cluster=0;
logic [ 7:0] cluster_sector_offset=8'h0;

logic [31:0] file_cluster=0;
logic [31:0] file_size = 0;

logic [ 7:0] cluster_size;
logic [31:0] first_fat_sector_no = 0;
logic [31:0] first_data_sector_no= 0;

// file parse result
wire fready;            // a file is find when fready = 1
wire [ 7:0] fnamelen;
wire [ 7:0] fname [52];
wire [15:0] fcluster;
wire [31:0] fsize;

reg search_fat = 1'b0;
enum {RESET, SEARCH_MBR, SEARCH_DBR, LS_ROOT_FAT16, LS_ROOT_FAT32, READ_A_FILE, DONE} fat_state = RESET;
enum logic [1:0] {UNASSIGNED, UNKNOWN, FAT16, FAT32} file_system=UNASSIGNED, fsystem;

assign filesystemtype = file_system;
assign fatstate = fat_state[2:0];

// store and parse MBR or DBR fields
logic [ 7:0] sector_content [512];
always @ (posedge clk)
    if(rvalid) begin
        sector_content[raddr] = rdata;
    end
always @ (*) begin
    is_boot_sector    = ( {sector_content['h1FE],sector_content['h1FF]}==16'h55AA );
    is_dbr            =    sector_content[0]==8'hEB || sector_content[0]==8'hE9;
    dbr_sector_no     =   {sector_content['h1C9],sector_content['h1C8],sector_content['h1C7],sector_content['h1C6]};

    bytes_per_sector  =   {sector_content['hC],sector_content['hB]};
    sector_per_cluster=    sector_content['hD];
    resv_sectors      =   {sector_content['hF],sector_content['hE]};
    number_of_fat     =    sector_content['h10];
    
    rootdir_itemcount =   {sector_content['h12],sector_content['h11]};
    
    sectors_per_fat   = {16'h0, sector_content['h17], sector_content['h16]};
    root_cluster      = 0;
    if(sectors_per_fat>0) begin  // FAT16 case
        fsystem           = FAT16;
    end else if(sector_content['h56]==8'h32) begin  // FAT32 case
        fsystem           = FAT32;
        sectors_per_fat   = {sector_content['h27],sector_content['h26],sector_content['h25],sector_content['h24]};
        root_cluster      = {sector_content['h2F],sector_content['h2E],sector_content['h2D],sector_content['h2C]};
    end else begin   // Unknown FileSystem
        fsystem           = UNKNOWN;
    end
end


always @ (posedge clk or negedge rst_n)
    if(~rst_n) begin
        read_start     = 1'b0;  read_sector_no = 0;
        fat_state      = RESET;
        file_system    = UNKNOWN;
        search_fat     = 1'b0;
        cluster_size        = 8'h0;
        first_fat_sector_no = 0;
        first_data_sector_no= 0;
        curr_cluster = 0;
        cluster_sector_offset = 8'h0;
        rootdir_sector = 0;
        rootdir_sectorcount = 16'h0;
    end else begin
        read_start     = 1'b0;
        if(read_done) begin
            case(fat_state)
            SEARCH_MBR :    if(is_boot_sector) begin
                                fat_state = SEARCH_DBR;
                                if(~is_dbr) read_sector_no = dbr_sector_no;
                            end else begin
                                read_sector_no++;
                            end
            SEARCH_DBR :    if(is_boot_sector && is_dbr ) begin
                                if(bytes_per_sector!=16'd512) begin
                                    fat_state = DONE;
                                end else begin
                                    file_system = fsystem;
                                    if(file_system==FAT16) begin
                                        cluster_size        = sector_per_cluster;
                                        first_fat_sector_no = read_sector_no + resv_sectors;
                                        
                                        rootdir_sectorcount = rootdir_itemcount/(16'd512/16'd32);
                                        rootdir_sector      = first_fat_sector_no + sectors_per_fat * number_of_fat;
                                        first_data_sector_no= rootdir_sector + rootdir_sectorcount - cluster_size*2;
                                        
                                        cluster_sector_offset = 8'h0;
                                        read_sector_no      = rootdir_sector + cluster_sector_offset;
                                        fat_state = LS_ROOT_FAT16;
                                    end else if(file_system==FAT32) begin
                                        cluster_size        = sector_per_cluster;
                                        first_fat_sector_no = read_sector_no + resv_sectors;
                                        
                                        first_data_sector_no= first_fat_sector_no + sectors_per_fat * number_of_fat - cluster_size * 2;
                                        
                                        curr_cluster        = root_cluster;
                                        cluster_sector_offset = 8'h0;
                                        read_sector_no      = first_data_sector_no + cluster_size * curr_cluster + cluster_sector_offset;
                                        fat_state = LS_ROOT_FAT32;
                                    end else begin
                                        fat_state = DONE;
                                    end
                                end
                            end
            LS_ROOT_FAT16 :     if(file_found) begin
                                    curr_cluster = file_cluster;
                                    cluster_sector_offset = 8'h0;
                                    read_sector_no = first_data_sector_no + cluster_size * curr_cluster + cluster_sector_offset;
                                    fat_state = READ_A_FILE;
                                end else if(cluster_sector_offset<rootdir_sectorcount) begin
                                    cluster_sector_offset ++;
                                    read_sector_no = rootdir_sector + cluster_sector_offset;
                                end else begin
                                    fat_state = DONE;
                                end
            LS_ROOT_FAT32 : if(~search_fat) begin
                                if(file_found) begin
                                    curr_cluster = file_cluster;
                                    cluster_sector_offset = 8'h0;
                                    read_sector_no = first_data_sector_no + cluster_size * curr_cluster + cluster_sector_offset;
                                    fat_state = READ_A_FILE;
                                end else if(cluster_sector_offset<(cluster_size-1)) begin
                                    cluster_sector_offset ++;
                                    read_sector_no = first_data_sector_no + cluster_size * curr_cluster + cluster_sector_offset;
                                end else begin   // read FAT to get next cluster
                                    search_fat = 1'b1;
                                    cluster_sector_offset = 8'h0;
                                    read_sector_no = first_fat_sector_no + curr_cluster_fat_no;
                                end
                            end else begin
                                search_fat = 1'b0;
                                cluster_sector_offset = 8'h0;
                                if(target_cluster=='h0FFF_FFFF || target_cluster=='h0FFF_FFF8 || target_cluster=='hFFFF_FFFF || target_cluster<2) begin
                                    fat_state = DONE;
                                end else begin
                                    curr_cluster = target_cluster;
                                    read_sector_no = first_data_sector_no + cluster_size * curr_cluster + cluster_sector_offset;
                                end
                            end
            READ_A_FILE  :  if(~search_fat) begin
                                if(cluster_sector_offset<(cluster_size-1)) begin
                                    cluster_sector_offset ++;
                                    read_sector_no = first_data_sector_no + cluster_size * curr_cluster + cluster_sector_offset;
                                end else begin   // read FAT to get next cluster
                                    search_fat = 1'b1;
                                    cluster_sector_offset = 8'h0;
                                    read_sector_no = first_fat_sector_no + (file_system==FAT16 ? curr_cluster_fat_no_fat16 : curr_cluster_fat_no);
                                end
                            end else begin
                                search_fat = 1'b0;
                                cluster_sector_offset = 8'h0;
                                if(file_system==FAT16) begin
                                    if(target_cluster_fat16>=16'hFFF0 || target_cluster_fat16<16'h2) begin
                                        fat_state = DONE;
                                    end else begin
                                        curr_cluster = {16'h0,target_cluster_fat16};
                                        read_sector_no = first_data_sector_no + cluster_size * curr_cluster + cluster_sector_offset;
                                    end
                                end else begin
                                    if(target_cluster=='h0FFF_FFFF || target_cluster=='h0FFF_FFF8 || target_cluster=='hFFFF_FFFF || target_cluster<2) begin
                                        fat_state = DONE;
                                    end else begin
                                        curr_cluster = target_cluster;
                                        read_sector_no = first_data_sector_no + cluster_size * curr_cluster + cluster_sector_offset;
                                    end
                                end
                            end
            //DONE       : 
            endcase
        end else begin
            case(fat_state)
            RESET      :    begin  fat_state = SEARCH_MBR;  end
            SEARCH_MBR :    begin  read_start=1'b1;  end
            SEARCH_DBR :    begin  read_start=1'b1;  end
            LS_ROOT_FAT16 : begin  read_start=1'b1;  end
            LS_ROOT_FAT32 : begin  read_start=1'b1;  end
            READ_A_FILE:    begin  read_start=1'b1;  end
            //DONE       : 
            endcase
        end
    end
    

always @ (posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        target_cluster = 0;
        target_cluster_fat16 = 16'h0;
    end else begin
        if(search_fat && rvalid) begin
            if(file_system==FAT16) begin
                if(raddr[8:1]==curr_cluster_fat_offset_fat16)
                    target_cluster_fat16[8*raddr[  0] +: 8] = rdata;
            end else if(file_system==FAT32) begin
                if(raddr[8:2]==curr_cluster_fat_offset)
                    target_cluster[8*raddr[1:0] +: 8] = rdata;
            end
        end
    end
end

sd_spi_sector_reader #(
    .SPI_CLK_DIV ( SPI_CLK_DIV    )
) sd_sector_reader(
    .clk         ( clk            ),
    .rst_n       ( rst_n          ),
    
    .sdcardtype  ( sdcardtype     ),
    .sdcardstate ( sdcardstate    ),
    
    .start       ( read_start     ),
    .sector_no   ( read_sector_no ),
    .done        ( read_done      ),
    
    .rvalid      ( rvalid         ),
    .raddr       ( raddr          ),
    .rdata       ( rdata          ),
    
    .spi_csn     ( spi_cs_n       ),
    .spi_clk     ( spi_clk        ),
    .spi_mosi    ( spi_mosi       ),
    .spi_miso    ( spi_miso       )
);

dir_parser root_dir_parser_inst(
    .clk        ( clk          ),
    .rst_n      ( rst_n        ),
    .rvalid     ( rvalid && (fat_state==LS_ROOT_FAT16||fat_state==LS_ROOT_FAT32) && ~search_fat  ),
    .raddr      ( raddr[4:0]   ),
    .rdata      ( rdata        ),
    
    .fready     ( fready       ),
    .fnamelen   ( fnamelen     ),
    .fname      ( fname        ),
    .fcluster   ( fcluster     ),
    .fsize      ( fsize        )
);

// compare Target filename with actual filename
always @ (posedge clk or negedge rst_n)
    if(~rst_n) begin
        file_found = 1'b0;
        file_cluster=0;
    end else begin
        if(fready && fnamelen==TARGET_FNAME_LEN) begin
            int i;
            for(i=0;i<TARGET_FNAME_LEN;i++) begin
                if(fname[TARGET_FNAME_LEN-1-i]!=TARGET_FNAME_UPPER[i*8+:8]) begin
                    break;
                end
            end
            if(i>=TARGET_FNAME_LEN) begin
                file_found = 1'b1;
                file_cluster = fcluster;
                file_size = fsize;
            end
        end
    end

logic [31:0] fptr = 0;
initial {outreq,outbyte} = {1'b0,8'h0};

always @ (posedge clk or negedge rst_n)
    if(~rst_n) begin
        fptr = 0;
        {outreq,outbyte} = {1'b0,8'h0};
    end else begin
        if(rvalid && fat_state==READ_A_FILE && ~search_fat && fptr<file_size) begin
            fptr++;
            {outreq,outbyte} = {1'b1,rdata};
        end else
            {outreq,outbyte} = {1'b0,8'h0};
    end

endmodule
