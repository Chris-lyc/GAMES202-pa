# GAMES202-pa

## PA0
![image](https://github.com/Chris-lyc/GAMES202-pa/blob/main/images/pa0.png)
## PA1
**PCSS软阴影，核心是分别从光源和观察点方向两次操作。第一次，从光源方向生成shadow map，第二次的核心步骤：**

1.在shading point周围一定范围内（可以固定范围，也可以用自适应方法）查询shadow map上的平均blocker depth

2.根据blocker depth计算filter核大小（因为点离遮挡物越近，阴影越硬，反之越软；filter核越大阴影越软）

3.在filter核范围内做PCF，即将shading point的深度与shadow map的深度进行比较，所得0/1值取平均

**加速方法：VSSM ，主要针对步骤1和3稀疏采样**

![image](https://github.com/Chris-lyc/GAMES202-pa/blob/main/images/pa1-1.png)
![image](https://github.com/Chris-lyc/GAMES202-pa/blob/main/images/pa1-2.png)

## PA2
**PRT (Precomputed Radiance Transfer) 适用于场景中仅光源会发生变化的情况**

将渲染方程中的L项用底层编码，如球谐函数SH表示。分别预计算好lighting项和light transport项的球谐函数系数。在渲染时仅需要将系数点乘（diffuse材质为向量点乘向量，glossy材质为向量点乘矩阵）即可，满足RT速度要求

**优点**：速度快，可以处理shadow情况

**缺点**：SH不足以描述高频信息、仅适用静态场景、存储数据量大

![image](https://github.com/Chris-lyc/GAMES202-pa/blob/main/images/pa2-CornellBox.png)
![image](https://github.com/Chris-lyc/GAMES202-pa/blob/main/images/pa2-GraceCathedral.png)
![image](https://github.com/Chris-lyc/GAMES202-pa/blob/main/images/pa2-Indoor.png)
![image](https://github.com/Chris-lyc/GAMES202-pa/blob/main/images/pa2-Skybox.png)

## PA3
**SSR (Screen-Space Reflections) 全局光照**

用于在已经完成渲染的图像中，再进行处理加入反射等效果。类似光线追踪的做法，模拟光的传播路径来计算比直接光照多一次弹射的光照结果

**核心在于**：在屏幕空间下，没有3D空间信息，用光线步进判断光线与物体的交点（可以使用Depth Mipmap加速）

获得交点后，再反射一次就可以得到间接光照

![image](https://github.com/Chris-lyc/GAMES202-pa/blob/main/images/pa3-cave.png)
![image](https://github.com/Chris-lyc/GAMES202-pa/blob/main/images/pa3-cube1.png)
![image](https://github.com/Chris-lyc/GAMES202-pa/blob/main/images/pa3-cube2.png)

## PA4
**PBR (physically-based rendering) 材质**

在微表面模型中，忽略了光在微表面间的多次弹射导致能量损失。粗糙度高的表面损失会更加严重。使用**Kulla-Conty**模型进行补偿

![image](https://github.com/Chris-lyc/GAMES202-pa/blob/main/images/pa4.png)
## PA5
**RTRT (Real-Time Ray Tracing)**

对于实时光线追踪来说，由于受到速度的严苛限制，往往只能在1SPP的情况下进行渲染，这将带来严重的噪点问题。对于这个问题，可以使用上一帧的渲染结果对当前帧进行修正。

**主要步骤：**

1.对当前帧进行普通的滤波降噪

2.使用上一帧信息对当前帧修正

​	通过MVPE矩阵找到当前帧中的一点，对应在上一帧中的位置

​	结合上一帧的结果修正当前帧（需要对上一帧进行clamp防止拖尾等现象）

单帧降噪：

![image](https://github.com/Chris-lyc/GAMES202-pa/blob/main/images/pa5-filter.png)

未降噪：

![image](https://github.com/Chris-lyc/GAMES202-pa/blob/main/images/pa5-input.png)

累计多帧降噪：

![image](https://github.com/Chris-lyc/GAMES202-pa/blob/main/images/pa5-result.png)
