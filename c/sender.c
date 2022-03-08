#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <net/if.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <netinet/ether.h>
#include <netpacket/packet.h>
 
unsigned short checksum(unsigned short *buf, int nword)
{
    unsigned long sum;
    for(sum=0; nword>0; nword--)
    {
        sum+=htons(*buf);
        buf++;
    }
    sum=(sum>>16) + (sum&0xffff);
    sum+=(sum>>16);
    return (~sum);
}
 
int main(int argc, char *argv[])
{
    int sock_raw_fd=socket(PF_PACKET, SOCK_RAW, htons(ETH_P_ALL));
    int len;
    unsigned char send_msg[1024];/*
    {
        0x74,0x27,0xea,0xb5,0xef,0xd8,   // 目的mac
        0x24,0x6e,0x96,0xc9,0x8a,0x82,   // 源mac        
        0x08,0x00,                       // 协议类型
        //   IP 
        0x45,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,
        0x80,17,  0x00,0x00,
        10,  221,  20,  11,
        10,  221,  20,  10,
         // UDP 
        0x1f,0x90,0x1f,0x90,
        0x00,0x00,0x00,0x00
    };
    int len=sprintf(send_msg+42,"%s","this is for the udp test");
    if(len%2==1)
    {
        len++;
    }
    *((unsigned short*)&send_msg[16])=htons(20+8+len);
    *((unsigned short*)&send_msg[14+20+4])=htons(8+len);
    
    unsigned char pseudo_head[1024]={
        10,221,20,11,
        10,221,20,10,
        0x00,17,0x00,0x00
    };
    *((unsigned short*)&pseudo_head[10])=htons(8+len);
    memcpy(pseudo_head+12, send_msg+34, 8+len);
    *((unsigned short*)&send_msg[24])=htons(checksum((unsigned short*)(send_msg+14), 20/2));
    *((unsigned short*)&send_msg[40])=htons(checksum((unsigned short *)pseudo_head, (12+8+len)/2));*/
    struct sockaddr_ll sll;
    struct ifreq req;
    char dst_mac[6]={0x00,0x01,0x02,0x03,0x04,0x05};
 
    strncpy(req.ifr_name,"argv[1]",IFNAMSIZ);
    if(-1==ioctl(sock_raw_fd, SIOCGIFINDEX, &req))
    {
        perror("ioctl");
        close(sock_raw_fd);
        exit(1);
    }
    bzero(&sll, sizeof(sll)); 
    sll.sll_ifindex=req.ifr_ifindex;
    sll.sll_family=AF_PACKET;
    sll.sll_halen=ETHER_ADDR_LEN;
    sll.sll_protocol=htons(ETH_P_IP);
    memcpy(sll.sll_addr,dst_mac,ETHER_ADDR_LEN);
 
    len=sendto(sock_raw_fd, send_msg, 14+20+8+len, 0, (struct sockaddr*)&sll, sizeof(sll));
    if(len==-1)
    {
        perror("sendto");
    }
    return 0;
}
