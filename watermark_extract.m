function W_userex = watermark_extract(I_rergb,Wide_R,Wide_C,emb_loc,num_region,th)

[M,N,C] = size(I_rergb);

if C ~= 1  %color image
    II = rgb2ycbcr(I_rergb);
    I1 = II(:,:,1);
else   %grayscale image
    I1 = I_rergb;
end

[frames,gss,dogss] = do_sift(I1, 'Verbosity', 1, 'NumOctaves', 4, 'Threshold', 0.1/3/2 ); 
frames = frames(:,find(frames(1,:)>Wide_R/2 & frames(1,:)<(M-Wide_R/2) & frames(2,:)>Wide_C/2 & frames(2,:)<(N-Wide_C/2)));
FR = frames';
EX = FR(:,5);
[A,B] = sort(EX,'descend');
FR = sortrows(FR,-5);
index = 1;
num_r = floor(num_region*2);
x = zeros(num_r,1);
y = zeros(num_r,1);
x(1) = frames(1,B(1));
y(1) = frames(2,B(1));
while index < num_r
    for i = index+1:size(FR,1)
        if abs((FR(i,1) - x(index))) <= Wide_R || abs((FR(i,2) - y(index))) <= Wide_C
            FR(i,5) = 0;
        else
        end
    end
    FR = FR( find(FR(:,5) ~= 0),1:5 );
    index = index + 1;
    x(index) = FR(index,1);
    y(index) = FR(index,2);
end
loc_x = zeros(num_r,9);
loc_y = zeros(num_r,9);
w_ex = zeros(num_r,Wide_C*Wide_R/64,9);
for i = 1:num_r
    loc_x(i,[1,4,7]) = x(i)-1;
    loc_x(i,[2,5,8]) = x(i);
    loc_x(i,[3,6,9]) = x(i)+1;
    loc_y(i,[1,2,3]) = y(i)-1;
    loc_y(i,[4,5,6]) = y(i);
    loc_y(i,[7,8,9]) = y(i)+1;
    w_ex(i,:,:) = extract(I1,loc_x(i,:),loc_y(i,:),emb_loc,Wide_R,Wide_C);
end
index = 1;
for i = 1:num_r
    for j = 1:9
        w1 = w_ex(i,:,j);
        for k = i+1:num_r
            for h = 1:9
                w2 = w_ex(k,:,h);
                judge_num = biterr(w1,w2);
                if judge_num < th
                    W_final(:,index) = w1;
                    W_final(:,index+1) = w2;
                    index = index + 2;
                end
            end
        end
    end
end
W_userex = W_final(:,1);
for i = 2 : size(W_final,2)
    W_userex = W_userex + W_final(:,i);
end
aver = size(W_final,2)/2;
for i = 1: length(W_userex)
    if W_userex(i) > aver
        W_userex(i) = 1;
    else
        W_userex(i) = 0;
    end
end




end