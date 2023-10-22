function [I_ex,Region] = Reg_ex(I,x,y,Wide_R,Wide_C)

I_ex = I;
num = length(x);
Region = zeros(Wide_R,Wide_C,num);
for i = 1:num
    Region(:,:,i) = I(x(i)-Wide_R/2+1:x(i)+Wide_R/2,y(i)-Wide_C/2+1:y(i)+Wide_C/2);
    I_ex(x(i)-Wide_R/2+1:x(i)+Wide_R/2,y(i)-Wide_C/2+1:y(i)+Wide_C/2) = floor(rand(Wide_R,Wide_C)*256);
    %I_ex(x(i)-Wide/2+1:x(i)+Wide/2,y(i)-Wide/2+1:y(i)+Wide/2) = 0;
end


end