# GAMES202-pa

## PA0
![image](https://github.com/Chris-lyc/GAMES202-pa/blob/main/images/pa0.png)
## PA1
**PCSS软阴影，核心是分别从光源和观察点方向两次操作。第一次，从光源方向生成shadow map，第二次的核心步骤：**

1.在shading point周围一定范围内（可以固定范围，也可以用自适应方法）查询shadow map上的平均blocker depth
2.根据blocker depth计算filter核大小（因为点离遮挡物越近，阴影越硬，反之越软；filter核越大阴影越软）
3.在filter核范围内做PCF，即将shading point的深度与shadow map的深度进行比较，所得0/1值取平均
**加速方法：VSSM 主要针对步骤1和3**
![image](https://github.com/Chris-lyc/GAMES202-pa/blob/main/images/pa1-1.png)
![image](https://github.com/Chris-lyc/GAMES202-pa/blob/main/images/pa1-2.png)

## PA2
**PRT适用于场景中仅光源会发生变化的情况**

将渲染方程中的L项用底层编码，如球谐函数SH表示。分别预计算好lighting项和light transport项的球谐函数系数。在渲染时仅需要将系数点乘（diffuse材质为向量点乘向量，glossy材质为向量点乘矩阵）即可，满足RT速度要求
![image](https://github.com/Chris-lyc/GAMES202-pa/blob/main/images/pa2-CornellBox.png)
![image](https://github.com/Chris-lyc/GAMES202-pa/blob/main/images/pa2-GraceCathedral.png)
![image](https://github.com/Chris-lyc/GAMES202-pa/blob/main/images/pa2-Indoor.png)
![image](https://github.com/Chris-lyc/GAMES202-pa/blob/main/images/pa2-Skybox.png)

## PA3
![image](https://github.com/Chris-lyc/GAMES202-pa/blob/main/images/pa3-cave.png)
![image](https://github.com/Chris-lyc/GAMES202-pa/blob/main/images/pa3-cube1.png)
![image](https://github.com/Chris-lyc/GAMES202-pa/blob/main/images/pa3-cube2.png)
## PA4
![image](https://github.com/Chris-lyc/GAMES202-pa/blob/main/images/pa4.png)
## PA5
![image](https://github.com/Chris-lyc/GAMES202-pa/blob/main/images/pa5-filter.png)
![image](https://github.com/Chris-lyc/GAMES202-pa/blob/main/images/pa5-input.png)
![image](https://github.com/Chris-lyc/GAMES202-pa/blob/main/images/pa5-result.png)
