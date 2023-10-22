function [ kk, t, a, b_encode ] =BCH_encode(mx, BCH_length)

n = BCH_length; %码长
t = 7; %纠错能力

m=0;
while(2^m-1~=n&&m<20)
    m=m+1;
end
if(m==20)
    disp('错误:只支持本原BCH码')
end

if((t>=floor((n-1)/2))||(t<=0))
    disp('错误:纠错能力不能为0或者不能太大')
end

%----------------------------------------------
a=gf(2,m);    %构造扩域,matlab自动只把a当做扩域中的本原元
for i=1:2:(2*t-1)    %求最小多项式,只找奇数项
    b=[1,a^i];   %让b分别为a^i...找每一个(这么定义是要卷积的)
    l=i;
    while a^i~=a^(2*l) %找共轭根系
        l=2*l;
        b=conv(b,[1,a^l]);%求最小多项式
    end
    if i==1
        g=b;
    else
        g=conv(g,b);    %求生成多项式 利用卷积,进行连乘
    end
end
%--------------------------------------------------
gx=double(g.x);%从扩域到数域 相当于变成多项式
kk=n-length(gx)+1;
%disp(['计算得码长 k=',num2str(k)])
%----------------------------------------------------
x1=zeros(1,length(gx));          %循环码编码方程中的
x1(1)=1;
c1=conv(x1,mx);                  %码字的前k位,编码方程第一项
[~,r]=deconv(c1,gx);
r=mod(r,2);                      %编码方程第二项
b_encode=mod(c1+r,2);                   %生成系统码,转换成为二进制
%disp(['编码后生成码序列为  ',num2str(c)])
end