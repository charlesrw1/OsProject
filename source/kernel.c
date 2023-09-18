#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#include "string.h"
#include "out.h"
#include "interrupt.h"
#include "ports.h"


typedef enum {
	VGA_COLOR_BLACK = 0,
	VGA_COLOR_BLUE = 1,
	VGA_COLOR_GREEN = 2,
	VGA_COLOR_CYAN = 3,
	VGA_COLOR_RED = 4,
	VGA_COLOR_MAGENTA = 5,
	VGA_COLOR_BROWN = 6,
	VGA_COLOR_LIGHT_GREY = 7,
	VGA_COLOR_DARK_GREY = 8,
	VGA_COLOR_LIGHT_BLUE = 9,
	VGA_COLOR_LIGHT_GREEN = 10,
	VGA_COLOR_LIGHT_CYAN = 11,
	VGA_COLOR_LIGHT_RED = 12,
	VGA_COLOR_LIGHT_MAGENTA = 13,
	VGA_COLOR_LIGHT_BROWN = 14,
	VGA_COLOR_WHITE = 15,
}vga_color;

const int VGA_WIDTH = 80;
const int VGA_HEIGHT = 25;

int terminal_row;
int terminal_col;
int terminal_color;
uint16_t* const terminal_buffer =(uint16_t*)0xb8000;


static inline void vga_enable_cursor(uint8_t cursor_start, uint8_t cursor_end)
{
	outb(0x3D4, 0x0A);
	outb(0x3D5, (inb(0x3D5) & 0xC0) | cursor_start);
 
	outb(0x3D4, 0x0B);
	outb(0x3D5, (inb(0x3D5) & 0xE0) | cursor_end);
}

static inline void vga_disable_cursor()
{
	outb(0x3D4, 0x0A);
	outb(0x3D5, 0x20);
}

static inline void vga_update_cursor(int x, int y)
{
	uint16_t pos = y * VGA_WIDTH + x;
 
	outb(0x3D4, 0x0F);
	outb(0x3D5, (uint8_t) (pos & 0xFF));
	outb(0x3D4, 0x0E);
	outb(0x3D5, (uint8_t) ((pos >> 8) & 0xFF));
}

static inline uint8_t vga_entry_color(vga_color fg, vga_color bg)
{
	return fg | bg<<4;
}

static inline uint16_t vga_entry_text(char c, uint8_t color)
{
	return (uint16_t)c | (uint16_t) color << 8;
}

static inline void vga_put_char_at(char c, uint8_t color, int x, int y)
{
	int index = y*VGA_WIDTH+x;
	terminal_buffer[index]=vga_entry_text(c,color);
}

void clear_vga_terminal()
{
	for(int y=0;y<VGA_HEIGHT;y++) {
		for(int x=0;x<VGA_WIDTH;x++) {
			vga_put_char_at(' ',terminal_color,x,y);
		}
	}
}

void vga_scroll_terminal(int lines)
{
	if(lines<=0)
		return;
	if(lines>=VGA_HEIGHT) {
		clear_vga_terminal();
		return;
	}

	uint16_t* src = &terminal_buffer[VGA_WIDTH*lines];
	size_t count = VGA_WIDTH*(VGA_HEIGHT-lines-1)*2;
	memmove(terminal_buffer,src,count);
	for(int y=VGA_HEIGHT-lines-1;y<VGA_HEIGHT;y++) {
		for(int x=0;x<VGA_WIDTH;x++)
			vga_put_char_at(' ',terminal_color,x,y);
	}
}

void init_vga_terminal()
{
	terminal_row=terminal_col=0;
	terminal_color = vga_entry_color(VGA_COLOR_LIGHT_GREY, VGA_COLOR_BLACK); 
	clear_vga_terminal();
}

void vga_put_char(char c)
{
	uint8_t update_cursor = 0;
	if(c=='\n')
	{
		terminal_col=0;
		terminal_row++;
		update_cursor=1;
	}
	else {
		vga_put_char_at(c,terminal_color,terminal_col,terminal_row);
		terminal_col++;
	}

	if(terminal_col>=VGA_WIDTH) {
		terminal_col=0;
		terminal_row++;
		update_cursor=1;
	}
	if(terminal_row>=VGA_HEIGHT) {
		terminal_row=0;
	}
	// leave 2 spaces
	if(terminal_row>=VGA_HEIGHT-1) {
		vga_scroll_terminal(1);
		terminal_row=VGA_HEIGHT-2;
	}
	if(update_cursor)
		vga_update_cursor(terminal_col,terminal_row);
}

void print_string(const char* str)
{
	int len = strlen(str);
	for(int i=0;i<len;i++) {
		vga_put_char(str[i]);
	}
}

void print_hex(uint64_t number, int bits)
{
	vga_put_char('0');
	vga_put_char('x');
	int digs = bits/4;
	for(int i=0;i<digs;i++)
	{
		int a = (number>>((digs-1-i)*4))&0xf;
		char c =0;
		if(a<=9) {
			c=a+'0';
		}
		else {
			c=a-10+'A';
		}
		vga_put_char(c);
	}
}
void print_hex32(uint32_t number)
{
	print_hex(number,32);
	vga_put_char('\n');
}

void error(const char* error_str)
{
	terminal_color=vga_entry_color(VGA_COLOR_WHITE,VGA_COLOR_BLUE);
	clear_vga_terminal();
	terminal_col=terminal_row=0;
	print_string(error_str);
	asm("cli");
	asm("hlt");
}
void vga_run_palette_tester()
{

}

struct elf_file_header
{

};
struct elf_program_header
{

};



#define MEM_MAP_ENTRY 0x1000
extern uint16_t mem_map_count;
typedef struct
{
	uint64_t base_addr;
	uint64_t length;
	uint32_t type;
	uint32_t ext_attributes;
}mmap_entry;

extern uint16_t dp_num_sectors;
extern uint16_t dp_dest_offset;
extern uint16_t dp_dest_segment;
extern uint64_t dp_src_sector;

extern uint8_t drive_num;
extern uint16_t drive_bytes_per_sector;

extern void bios_call(int call_type);

// use for reading from bios
#define CD_SECTOR 0x800
static uint8_t load_buffer[CD_SECTOR];

#define LOAD_BASE (uint8_t*)0x100000 // 1mb

void read_into_dest(uint8_t* dest_addr, int lba_sector)
{
	ASSERT(lba_sector>=0x10&&lba_sector<0xff);

	dp_num_sectors = CD_SECTOR/drive_bytes_per_sector;
	dp_dest_segment = 0;
	dp_dest_offset = load_buffer;
	dp_src_sector = lba_sector*dp_num_sectors;
	bios_call(0);
	if(dest_addr!=NULL) {
		memcpy(dest_addr,load_buffer,CD_SECTOR);
	}
}

#define ISO_HIDDEN_FILE 1
#define ISO_IS_SUBDIRECTORY 2

typedef struct __attribute__((packed))
{
	uint8_t directory_length;	// in bytes
	uint8_t ext_attrib_length;
	uint32_t extent_lba;		// lba (2kb sectors)
	uint32_t unused1;
	uint32_t extent_length;
	uint32_t unused2;
	uint8_t data_time[7];
	uint8_t file_flags;
	char unused3;
	char unused4;
	uint32_t volume_seq_num;
	uint8_t file_id_length;
	// variable length file id
	char remaining_bytes[222];	// undefined past directory_length-struct size
} directory_record; 

directory_record root_record={};
directory_record active_record={};

const char* strchr(const char* str, unsigned char c)
{
	while(*str) {
		if(*str==c)
			return *str;
		++str;
	}
	return NULL;
}


int strcmp(const char* str1, const char* str2)
{
	int i =0;
	while(*str1 && *str2 && *str1 == *str2) {
		++i;
		++str1;
		++str2;
	}
	return (*str1==*str2)?0:i;
}


int divceil(int x, int y) {
	return x / y + (x % y > 0);
}


void directory_to_upper(char* string) 
{
	while(*string) {
		if(*string>=97&&*string<=122)
			*string = 'A'+(*string-'a');
		string++;
	}
}

void read_directory_into_memory(directory_record* directory, char* where)
{
	int sectors_to_load = divceil(directory->extent_length,CD_SECTOR);
	uint8_t* addr = where;
	int lba_start = directory->extent_lba;
	ASSERT(lba_start>=0x10 && lba_start <80);
	for(int i=0;i<sectors_to_load;i++) {
		read_into_dest(addr,lba_start+i);
		addr += CD_SECTOR;
	}
}

bool compare_dir_name(const char* pattern, const char* dir_name, int dir_name_len)
{
	int plen = strlen(pattern);
	if(dir_name_len<plen)
		return false;
	if(memcmp(pattern,dir_name,plen)!=0)
		return false;
	if(dir_name_len>plen && dir_name[plen]!=';'&&dir_name[plen]!=0)
		return false;
	return true;
}

directory_record* find_record_in_directory(const char* pattern, uint8_t* start, int sectors)
{
	uint8_t* base = start;
	int cur_sector = 0;
	int sec_offset = 0;
	while(!(cur_sector==sectors || sec_offset >= CD_SECTOR))
	{
		directory_record* rec = (directory_record*)(base+sec_offset);
		sec_offset+=rec->directory_length;
		if(rec->directory_length==0) {
			sec_offset = 0;
			cur_sector++;
			continue;
		}
		if(rec->file_flags&ISO_HIDDEN_FILE)
			continue;
		bool suc = compare_dir_name(pattern,rec->remaining_bytes,rec->file_id_length);
		if(suc)
			return rec;
	}
	return NULL;
}

// find the record for filepath and place it in active_record
bool find_record(const char* filepath)
{
	ASSERT(strlen(filepath)<255);
	if(*filepath == '.')
		filepath++;
	if(*filepath=='/')
		filepath++;
	ASSERT(*filepath!=0);

	int active_dir_lba;
	int acrive_dir_len;
	char dirbuffer[256];
	const char* iter = filepath;

	directory_record dir = root_record;
	while(1)
	{
		iter = strsplit(iter,'/',dirbuffer);
		directory_to_upper(dirbuffer);
		ASSERT(*dirbuffer!=0);

		read_directory_into_memory(&dir,LOAD_BASE);
		int sectors = divceil(dir.extent_length,CD_SECTOR);
		directory_record* found = find_record_in_directory(dirbuffer,LOAD_BASE,sectors);
		if(!found)
		{
			return false;
		}
		else if(iter == NULL || *iter == 0)
		{
			// found file
			ASSERT(!(found->file_flags&ISO_IS_SUBDIRECTORY));
			active_record = *found;
			return true;
		}
		else
		{
			dir = *found;
		}
		ASSERT(dir.file_flags&ISO_IS_SUBDIRECTORY);
	}

	return false;
}


void load_kernel_off_iso()
{
	// First find 

	read_into_dest(LOAD_BASE,0x10);
}

void kmain()
{
	init_vga_terminal();
	print_string("Welcome to kmain\n");

	//interrupt_init();


	// get primary volume descriptor
	read_into_dest(NULL,0x10);
	root_record = *(directory_record*)(load_buffer+156);
	ASSERT(memcmp("CD001",load_buffer+1,5)==0);

	bool success = find_record("folder/OPENME.txt");
	ASSERT(success);
	print_string("boot/OPENME.txt: \n");
	read_directory_into_memory(&active_record,LOAD_BASE);

	char* kernelc = LOAD_BASE;
	for(int i=0;i<active_record.extent_length;i++)
	{
		vga_put_char(kernelc[i]);
	}
	vga_put_char('\n');
	print_string("done!\n");

	for(int i=0;i<mem_map_count;i++)
	{
		mmap_entry* entry = (mmap_entry*)(MEM_MAP_ENTRY + i*20);
		print_string("entry: ");
		print_string("mem: ");
		print_hex(entry->base_addr,64);
		vga_put_char(' ');
		print_hex(entry->length,64);
		vga_put_char('\n');
	}
	print_hex(0xaa00bb00cc00dd,64);
	vga_put_char('\n');
	
	print_string("drive info:\n");
	print_hex(drive_num,8);
	vga_put_char('\n');
	print_hex(drive_bytes_per_sector,16);
	vga_put_char('\n');


	for(;;){}
}