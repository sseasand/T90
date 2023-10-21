function Calculating_T90_PROCESS(excelFile, target, y_end, PSUM, TSUM)
    % 读取Excel文件
    data = xlsread(excelFile);

    % 初始化行数
    row = 1;

    % 初始化标志，用于指示是否找到结果
    found = false;

    while row <= size(data, 1)
        % 读取第一列和第二列的数据
        col1Data = data(row, 1);
        col2Data = data(row, 2);
        %-----------------------------------------------------------------
        n=2   ;%组分数量
        y=[0.3 0.7;0.3 0.7;0 0];
        
        y(3,1)=y_end;
        
        P_sum=PSUM*1e3;

        T_sum=TSUM;

        y(3,2)=1-y(3,1);%各个釜中各组分占比(甲烷 氮气)
        P=P_sum.';
        Tm=273.15+T_sum.';
        P(1,3) =col1Data.*1e3;
        Tm(1,3) = 273.15+col2Data;
        %检测组分输入，可忽略
        for i=1:3    
        N=sum(y,2);
        if N(i,1)==1
            N=1;
        else
            disp(['请检查输入组分占比是否正确'])
            return
        end;
        end;

        for d=1:3
            T=Tm(d);
        %预先查询的参数
        R=8.314                            ; %R=摩尔气体常数
        F   =[0.455336,0.516798]           ; %F 查询《多元气液平衡和精馏》P41
        KISc=[0.324,   0.329   ]           ; %ξc查询《多元气液平衡和精馏》P41
        %如根据与w相关性计算则按照《多元气液平衡和精馏》P42公式计算
        %w=[0.011,0.039]         %可查得
        %F=0.452413+1.30982.*w-0.295937.*w.^2
        %KISc=0.329062-0.076799.*w+0.0211947.*w.^2
        Tc=[190.6  126.2]                   ;%临界温度查询得
        Pc=[4.6    3.39 ]*1e6               ;%临界压力查询得
        Tr=T./Tc                            ;%对比温度
        k(1,2)=0.032                        ;
        k(2,1)=0.032                        ;%二元相互作用因子，PT方程kij见《气体水合物科学与技术》p508

        %求解Ωa Ωb Ωc α
        omega_c=1-3.*KISc;
        p1=[1,2-3.*KISc(1),3.*KISc(1).^2,-KISc(1).^3];
        omega_b(1)=min(roots(p1))          ;%三次方程的根只可能是1实根2虚根或3实根,故可使用min
        p2=[1,2-3.*KISc(2),3.*KISc(2).^2,-KISc(2).^3];
        omega_b(2)=min(roots(p2));
        omega_a=3.*KISc.^2+3.*(1-2.*KISc).*omega_b+omega_b.^2+1-3.*KISc;
        Alfa=(1+F.*(1-Tr.^0.5)).^2;
    
        %求解P41中abc
        a=omega_a.*Alfa.*R.^2.*Tc.^2./Pc;
        b=omega_b.*R.*Tc./Pc;
        c=omega_c.*R.*Tc./Pc;

        %求解P42中abc
        for y1=1:3
        for i=1:n
            for j=1:n
                a1(i,j)=(a(i).*a(j)).^0.5.*(1-k(i,j));
            end;
        end;
        for i=1:n
            for j=1:n
                a2(i,j)=y(y1,i).*y(y1,j).*a1(i,j);
            end;
        end;
        a_end=sum(a2,"all");
        for i=1:n
            b1(i)=y(y1,i).*b(i);
        end;
        b_end=sum(b1);
        for i=1:n
           c1(i)=y(y1,i).*c(i);
        end;
        c_end=sum(c1);

        %求解P42中ABC
        A(1,y1)=a_end.*P(y1)./(R.^2.*T.^2);
        B(1,y1)=b_end.*P(y1)./(R.*T);
        C(1,y1)=c_end.*P(y1)./(R.*T);
        end;

        %求解z
        for i=1:3
        z1=roots([1,C(i)-1,A(i)-2*B(i)*C(i)-B(i).^2-B(i)-C(i),(B(i).*C(i)+C(i)-A(i)).*B(i)]);%计算压缩因子
        z2(i)=max(z1);
        end;


        m=6;                       %水合数
        deltaV=4.6e-6;             %水合物和水之间的摩尔体积差
        V0=425e-6;                 %反应釜体积
        Vt=1000e-6;                %平衡釜的体积
        Vl=120e-6;                 %溶液体积
        z3(1,1)=0.3;z3(1,2)=0.7;z3(2,1)=y(3,1);z3(2,2)=y(3,2);     %原料气、平衡相中CH4和N2的摩尔分数
        nt=P(1).*Vt./(z2(1).*R.*Tm(1))-P(2).*Vt./(z2(2).*R.*Tm(2));%注入釜中气体摩尔数
        n_Ht=(nt-P(3).*(V0-Vl)./(z2(3).*R.*Tm(3)))./(1-m.*P(3).*deltaV./(z2(3).*R.*Tm(3)));%水合物相中的CH4摩尔数
        Ve=V0-Vl-m.*deltaV.*n_Ht                                  ;%反应釜中平衡时气体体积
        ne=P(3).*Ve./(z2(3).*R.*Tm(3))                            ;%反应釜中平衡气相摩尔数
        n1=nt.*z3(1,1)-ne.*z3(2,1)                                ;%吸收的CH4的摩尔数
        n2=nt.*z3(1,2)-ne.*z3(2,2)                                ;%吸收的N2的摩尔数
        x1=n1/(n1+n2)                                             ;%水合物相CH4的摩尔分数
        x2=n2/(n1+n2)                                             ;%水合物相N2的摩尔分数
        fai=22400.*nt./Vl                                         ;%初始气液体积比φ
        S=(x1./z3(2,1))./(x2./z3(2,2))                            ;%分离比
        R1=n1./(nt.*z3(1,1))                                      ;%回收率
        result=n1+n2                                              ;
        end


        %------------------------------------------------------------------
        
        % 将 result 转换为 double 类型
        result = double(result);

        % 将 target 转换为 double 类型
        target = double(target);

     

        % 检查是否大于等于目标数
        tolerance = 1e-6; % 定义容差值，根据你的需求设置合适的值
        if result >= (target.*0.9 - tolerance)
            fprintf('在第 %d 行找到t90数据 \n压力为：%f \n温度为：%f \n吸收摩尔数为：%f\n', row, col1Data, col2Data, result);
            found = true;
            break;
        end

    % 为下一次迭代更新行数
    row = row + 1;
    end

    % 如果未找到结果，输出未找到信息
    if ~found
        fprintf('未找到结果大于等于目标数。\n');
    end
end

