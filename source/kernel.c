#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#include "string.h"
#include "out.h"
#include "interrupt.h"


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

void print_hex32(uint32_t number)
{
	vga_put_char('0');
	vga_put_char('x');

	for(int i=0;i<8;i++)
	{
		int a = (number>>((7-i)*4))&0xf;
		char c =0;
		if(a<=9) {
			c=a+'0';
		}
		else {
			c=a-10+'A';
		}
		vga_put_char(c);
	}
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

void kmain()
{
	init_vga_terminal();
	print_string("Welcome to kmain\n");

	interrupt_init();
	printf("abc");

	print_string("done!\n");

	for(;;){}
}