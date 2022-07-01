#include <bits/stdc++.h>



int main() {
    freopen("kosarak.dat.txt", "r", stdin);
    srand(47);


    std::ofstream flow1, flow2;
    flow1.open("flow1.txt");
    flow2.open("flow2.txt");
    
    int x;
    while (scanf("%d", &x) == 1) {
        int rd = rand() & 1;
        if (rd) {
            flow1 << x << "\n";
        } else {
            flow2 << x << "\n";
        }
    }
    flow1.close();
    flow2.close();
    return 0;
}