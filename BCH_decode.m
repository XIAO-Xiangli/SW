function [ b ] =BCH_decode( b_arb, b_encode, k, t, a )

n = 63; %码长
enum=0;
for i=1:n
    if b_arb(i)~=b_encode(i)
        enum=enum+1;
    end
end
%disp(['水印提取后出错 ',num2str(enum),' 位(可最多纠正七位错误)'])
disp(['There are ',num2str(enum),'-bit errors after watermark extraction (up to 7-bit errors can be corrected)'])

%-----------------------------------------------------
s=a+a;                 %构造伴随式,初始化s
for i=1:2*t
    s(i)=a+a;
    for j=1:n
        s(i)=s(i)+b_arb(j)*a^((n-j)*i);
    end
end
for e=t:-1:1            %降阶
    A=a+a;
    for i=1:e
        for j=1:e
            A(i,j)=s(e+i-j);
        end
    end
    if det(A)~=0 
        break; %判断行列式是否为奇异,是就继续降
    end
end
d=rank(A);             %开始求方程组
B=a+a;
for i=1:d
    B(i)=s(d+i);
end
if A==a+a              %接受的码字出错的情况
    b=b_arb;
    E=zeros(1,n);
else
    sigma=A\(B');      %错误位置多项式的系数
    E=zeros(1,n);
    x=a+a;
    ki=1;
    for i=1:n          %试根
        h=a^0;
        for j=1:d
            h=h+sigma(j)*a^(i*j);
        end
        if h==a+a
            x(k)=a^(n-i);
            E(i)=1;   %错误图样,可以不用求具体根,找到位置即可
            ki=ki+1;
        end
    end
    b=mod(E+b_arb,2);   %校正接收码字
end
b=b(1:k);
%disp(['错误图样为  ',num2str(E)])
%disp(['译码结果为  ',num2str(cc)])
end