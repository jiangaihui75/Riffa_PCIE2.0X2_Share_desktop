# Riffa_PCIE2.0X2_Share_desktop

<img width="482" alt="image" src="https://user-images.githubusercontent.com/94519594/160595858-7aa801da-303e-4d74-a149-77ebc1a00d15.png">


1.软件环境：Vivado 2018.2、ModelSim、ILA、PC机

2.硬件环境：xc7a75tfgg484-2、MT41K128M16JT

2.项目描述： 

	(1).使用 Riffa 框架进行 PCIe 接口的应用开发，PC 端有 Riffa 自带的驱动 API，Riffa 框架主要完成对 TLP的封包和解包，以及获得更加简洁的用户接口时序。使用 VS2015 编写一个简单的 MFC 程序对 Riffa的 API 以及用户程序进行封装，从而可以直接通过点击按钮的方式把数据下发到板卡。PC 端需要完成对桌面进行截屏，截屏数据保存到内存上，并由 Riffa 提供的 API 把数据传输到板卡上；（上位机开发程序不是本人完成）
	(2).Riffa 模块使用了两个通道，硬件接口有 2 对接口，分别用于图像的配置和数据的传输。通过 Riffa 模块可以直接获取图像数据。DDR_CTRL 模块用于对 MIG 的 IP 核进行封装，从而使 DDR3 的控制时序更加简洁、易用；HDMI 驱动模块则用于 HDMI 设备的驱动显示。
	(3). 实现效果：HDMI 显示设备可以正常显示 PC 端的桌面，显示模式 1080P 模式，实测显示写的带宽约
800MBps。
