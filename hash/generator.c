#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>


const int M = 1024;

char s[M][M];
int ans[M];


int check(int x) {
    for(int i=0;i<x;++i) {
        int t=0;
        for(int j=0;j<5;++j) if (s[i][j] != s[x][j]) t=1;
        if (!t) return 1;
    }
    return 0;
}

int main() {
    freopen("a.txt", "w", stdout);

    int n = 500;
    for (int i=0; i<n; ++i) {
        while (1) {
            for(int j = 0;j < 5; ++j) s[i][j] = rand()%26+'a';

            if (!check(i)) break;
        }
    }

    int m = 20000;
    for(int i=0; i<m; ++i) {
        int idx = rand()%n;
        for(int j=0;j<5;++j) putchar(s[idx][j]);
        ++ans[idx];
        puts("");
    }

    puts("asd");

    for(int i=0;i<n;++i) {
        for(int j=0;j<5;++j) putchar(s[i][j]);
        
        printf("   %d\n", ans[i]);
    }
}