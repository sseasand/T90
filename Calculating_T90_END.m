clc;clear;
% 设置Excel文件名和目标数
excelFile = '2222.xlsx';

% 吸收摩尔数
target = 0.20098;

%最终CH4含量
y_end=17.18548119e-2;

%压力分布
PSUM=[6055.609863
5131.288454
];

%温度分布
TSUM=[0.559600626
0.702530329
];

% 调用函数
 Calculating_T90_PROCESS(excelFile, target, y_end, PSUM, TSUM)

% 打开Excel文件
winopen(excelFile);

