function I_re = Reg_re(II_d,x,y,Wide_R,Wide_C,Region_dec)

I_re = II_d;
num = length(x);
for i = 1:num
    I_re(x(i)-Wide_R/2+1:x(i)+Wide_R/2,y(i)-Wide_C/2+1:y(i)+Wide_C/2,1) = Region_dec(:,:,i);
end

end