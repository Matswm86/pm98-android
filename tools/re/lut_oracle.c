#include <stdio.h>
#include <string.h>
#include <stdint.h>
static const unsigned char C1b[8]={0x28,0x2d,0x44,0x54,0xfb,0x21,0x59,0x3f};
static const unsigned char C2b[8]={0,0,0,0,0,0,0xf0,0x40};
static const unsigned char C3b[8]={0,0,0,0,0,0,0xf0,0x3e};
static const unsigned char C4b[8]={0x76,0xc8,0xc9,0x6d,0x30,0x5f,0xc4,0x40};
static int32_t cos_x87(int k){
    double c1,c2; memcpy(&c1,C1b,8); memcpy(&c2,C2b,8);
    unsigned short ocw,tcw; int32_t out; long double r;
    __asm__ __volatile__("fnstcw %0":"=m"(ocw));
    __asm__ __volatile__("fildl %1\n\tfmull %2\n\tfcos\n\tfmull %3":"=t"(r):"m"(k),"m"(c1),"m"(c2));
    tcw=(ocw&~0x0C00)|0x0C00; __asm__ __volatile__("fldcw %0"::"m"(tcw));
    __asm__ __volatile__("fistpl %0":"=m"(out):"t"(r):"st");
    __asm__ __volatile__("fldcw %0"::"m"(ocw)); return out;
}
static int16_t atan_x87(int i){
    double c3,c4; memcpy(&c3,C3b,8); memcpy(&c4,C4b,8);
    unsigned short ocw,tcw; int32_t out; long double r;
    __asm__ __volatile__("fnstcw %0":"=m"(ocw));
    __asm__ __volatile__("fildl %1\n\tfmull %2\n\tfld1\n\tfpatan\n\tfmull %3":"=t"(r):"m"(i),"m"(c3),"m"(c4));
    tcw=(ocw&~0x0C00)|0x0C00; __asm__ __volatile__("fldcw %0"::"m"(tcw));
    __asm__ __volatile__("fistpl %0":"=m"(out):"t"(r):"st");
    __asm__ __volatile__("fldcw %0"::"m"(ocw)); return (int16_t)out;
}
int main(void){
    FILE*fc=fopen("/tmp/cos_lut.txt","w");
    for(int k=0;k<4096;k++) fprintf(fc,"%d\n",cos_x87(k));
    fclose(fc);
    FILE*fa=fopen("/tmp/atan_lut.txt","w");
    for(int j=0;j<=8192;j++) fprintf(fa,"%d\n",atan_x87(8*j));
    fclose(fa);
    /* simple checksums for quick parity */
    long sc=0,sa=0; int kk;
    for(kk=0;kk<4096;kk++) sc=sc*131+cos_x87(kk);
    for(kk=0;kk<=8192;kk++) sa=sa*131+atan_x87(8*kk);
    printf("cos rows=4096 fnv-ish=%ld\n",sc);
    printf("atan rows=8193 fnv-ish=%ld\n",sa);
    return 0;
}
