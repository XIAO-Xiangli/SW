clc; clear;
Wide_R = 64;
Wide_C = 64;
num_region = 6;
r = 2;
L = 24;
BCH_length = 63;
th = 6;

% load image
[filename,pathname,index] = uigetfile('*.jpg;*.bmp;*.tiff;*.png');
while index == 0
    return;
end
I = imread([pathname,filename]);

%Default watermark embedding
[M,N,C] = size(I);
if C ~= 1  %color image
    II = rgb2ycbcr(I);
    I1 = II(:,:,1);
else   %grayscale image
    I1 = I;
end
[frames,gss,dogss] = do_sift(I1, 'Verbosity', 1, 'NumOctaves', 4, 'Threshold', 0.1/3/2 ); 
frames = frames(:,find(frames(1,:)>=Wide_R/2 & frames(1,:)<=(M-Wide_R/2) & frames(2,:)>=Wide_C/2 & frames(2,:)<=(N-Wide_C/2)));
FR = frames';
EX = FR(:,5);
[A,B] = sort(EX,'descend');
FR = sortrows(FR,-5);
index = 1;
x = zeros(num_region,1);
y = zeros(num_region,1);
x(1) = frames(1,B(1));
y(1) = frames(2,B(1));
while index < num_region
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
[I_ex,Region] = Reg_ex(I1,x,y,Wide_R,Wide_C);

rng(1);
W_de = randi(2,Wide_R/8,Wide_C/8)-1;
rng('shuffle');
emb_loc = randi(2,Wide_R/8,Wide_C/8)-1;
Region_emb = zeros(Wide_R,Wide_C,2*num_region);
index = 1;
for i = 1 : num_region
    temp = Region(:,:,i);
    temp_f = temp;
    for j = 8 : 8 : Wide_R
        for k = 8 : 8 : Wide_C
            if emb_loc(j/8,k/8) == 0
               loc_one = [5,4]; loc_two = [5,5];
            else
               loc_one = [4,5]; loc_two = [5,4];
            end
            temp(j-7:j,k-7:k) = embed(temp(j-7:j,k-7:k),W_de(j/8,k/8),loc_one,loc_two,r);
            temp_f(j-7:j,k-7:k) = embed(temp_f(j-7:j,k-7:k),abs(W_de(j/8,k/8)-1),loc_one,loc_two,r);
        end
    end
    Region_emb(:,:,index) = temp;
    Region_emb(:,:,index+1) = temp_f;
    index = index + 2;
end

index = 1;
s = zeros(num_region,1);
for i = 1 : num_region
    s1 = ssim(Region(:,:,i),Region_emb(:,:,index));
    s2 = ssim(Region(:,:,i),Region_emb(:,:,index+1));
    s(i) = (s1+s2)/2;
    index = index + 2;
end
[a,b] = sort(s,'descend');
num_region_new = round(num_region*0.8);
Region_emb_new = zeros(Wide_R,Wide_C,2*num_region_new);
x_new = zeros(num_region_new,1);
y_new = zeros(num_region_new,1);
index = 1;
for i = 1 : num_region
    if i <= num_region_new
        Region_emb_new(:,:,index) = Region_emb(:,:,2*b(i)-1);
        Region_emb_new(:,:,index+1) = Region_emb(:,:,2*b(i));
        x_new(i) = x(b(i)); 
        y_new(i) = y(b(i));
        index = index + 2;
    else
        I_ex = Reg_re(I_ex,x(b(i)),y(b(i)),Wide_R,Wide_C,Region(:,:,b(i)));
    end
end
Region_emb = Region_emb_new;
x = x_new; y = y_new;
num_region = num_region_new;
% figure;
% imshow(I_ex);

%Encryption processing
U = U_gen(M);
V = V_gen(N);
if C ~= 1
    PL = zeros(M,C);
    PR = zeros(N,C);
    [PL(:,1),PR(:,1)] = P_gen(M,N);
    [PL(:,2),PR(:,2)] = P_gen(M,N);
    [PL(:,3),PR(:,3)] = P_gen(M,N);
else
    [PL,PR] = P_gen(M,N);
end
u = zeros(8,2*Wide_R*Wide_C/64);
v = zeros(8,2*Wide_R*Wide_C/64);
pl = zeros(Wide_R,num_region);
pr = zeros(Wide_C,num_region);
for i = 1:2*Wide_R*Wide_C/64
    u(:,i) = U_gen(8);
    v(:,i) = V_gen(8);
end
for i = 1:num_region
    [pl(:,i),pr(:,i)] = P_gen(Wide_R,Wide_C);
end

II_e = II;
K_matrix = uint8(mod(floor(U*V), 256));
if C ~= 1
    II_e(:,:,1) = I_ex;
    for i = 1:C
        temp = II_e(:,:,i);
        temp = bitxor(temp,K_matrix);
        temp = temp';
        temp(:,PL(:,i)) = temp(:,1:M);
        temp = temp';
        temp(:,PR(:,i)) = temp(:,1:N);
        II_e(:,:,i) = temp;        
    end
else
    II_e = bitxor(II_e,K_matrix);
    II_e = II_e';
    II_e(:,PL) = II_e(:,1:M);
    II_e = II_e';
    II_e(:,PR) = II_e(:,1:N);
end
index = 1;
Region_enc = Region_emb;
v = v';
for i = 1:num_region
    ind = 1;
    for j = 8 : 8 : Wide_R
        for k = 8 : 8 : Wide_C
            temp = Region_emb(j-7:j,k-7:k,index);
            temp_f = Region_emb(j-7:j,k-7:k,index+1);
            k_matrix = uint8(mod(floor(u(:,ind)*v(ind,:)), 256));
            temp = bitxor(uint8(temp),k_matrix);
            k_matrix = uint8(mod(floor(u(:,ind+1)*v(ind+1,:)), 256));
            temp_f = bitxor(uint8(temp_f),k_matrix);
            Region_enc(j-7:j,k-7:k,index) = temp;
            Region_enc(j-7:j,k-7:k,index+1) = temp_f;
            ind = ind + 2;
        end
    end
    temp = Region_enc(:,:,index);
    temp = temp';
    temp(:,pl(:,i)) = temp(:,1:Wide_R);
    temp = temp';
    temp(:,pr(:,i)) = temp(:,1:Wide_C);
    temp_f = Region_enc(:,:,index+1);
    temp_f = temp_f';
    temp_f(:,pl(:,i)) = temp_f(:,1:Wide_R);
    temp_f = temp_f';
    temp_f(:,pr(:,i)) = temp_f(:,1:Wide_C);
    Region_enc(:,:,index) = temp;
    Region_enc(:,:,index+1) = temp_f;
    index = index + 2;
end

%show
II_ergb = ycbcr2rgb(II_e);
figure;
imshow(II_ergb);
imwrite(II_ergb,'en.png');

% imwrite(uint8(Region_enc(:,:,1)),'01.png');
% imwrite(uint8(Region_enc(:,:,2)),'02.png');
% imwrite(uint8(Region_enc(:,:,3)),'03.png');
% imwrite(uint8(Region_enc(:,:,4)),'04.png');
% imwrite(uint8(Region_enc(:,:,5)),'05.png');
% imwrite(uint8(Region_enc(:,:,6)),'06.png');
% imwrite(uint8(Region_enc(:,:,7)),'07.png');
% imwrite(uint8(Region_enc(:,:,8)),'08.png');
% imwrite(uint8(Region_enc(:,:,9)),'09.png');
% imwrite(uint8(Region_enc(:,:,10)),'10.png');

%Distribution of decryption keys
W = randi([0,1],L,1);
[kk, t, a, W_encode] = BCH_encode(W, BCH_length);
W_encode(64) = 0;
W_matrix = reshape(W_encode,Wide_R/8,Wide_C/8);
W_matrix = W_matrix';
W_user = bitxor(W_de,W_matrix);
temp = W_user';
W_vec = temp(:);

u_user = zeros(8,Wide_R/8*Wide_C/8);
v_user = zeros(Wide_R/8*Wide_C/8,8);
index = 1;
for i = 1:Wide_R/8*Wide_C/8
    if W_vec(i) == 0
        u_user(:,i) = u(:,index);
        v_user(i,:) = v(index,:);
    else
        u_user(:,i) = u(:,index+1);
        v_user(i,:) = v(index+1,:);
    end
    index = index + 2;
end

%Image decryption
index = 1;
for i = 1:num_region
    temp = Region_enc(:,:,index);
    temp = temp';
    temp(:,1:Wide_R) = temp(:,pl(:,i));
    temp = temp';
    temp(:,1:Wide_C) = temp(:,pr(:,i));
    Region_enc(:,:,index) = temp;
    temp_f = Region_enc(:,:,index+1);
    temp_f = temp_f';
    temp_f(:,1:Wide_R) = temp_f(:,pl(:,i));
    temp_f = temp_f';
    temp_f(:,1:Wide_C) = temp_f(:,pr(:,i));
    Region_enc(:,:,index+1) = temp_f;
    index = index + 2;
end
Region_user = zeros(Wide_R,Wide_C,num_region);
index = 1;
for i = 1:num_region
    temp = Region_enc(:,:,index);
    temp_f = Region_enc(:,:,index+1);
    for j = 8 : 8 : Wide_R
        for k = 8 : 8 : Wide_C
            if W_user(j/8,k/8) == 0
                Region_user(j-7:j,k-7:k,i) = temp(j-7:j,k-7:k);
            else
                Region_user(j-7:j,k-7:k,i) = temp_f(j-7:j,k-7:k);
            end
        end
    end
    index = index + 2;
end
Region_dec = Region_user;
for i = 1:num_region
    temp = Region_user(:,:,i);
    index = 1;
    for j = 8 : 8 : Wide_R
        for k = 8 : 8 : Wide_C
            k_matrix = uint8(mod(floor(u_user(:,index)*v_user(index,:)), 256));
            temp(j-7:j,k-7:k) = bitxor(uint8(temp(j-7:j,k-7:k)),k_matrix);
            index = index + 1;
        end
    end
    Region_dec(:,:,i) = temp;
end
II_d = II_e;
K_matrix = uint8(mod(floor(U*V), 256));

if C ~= 1
    for i = 1:C
        temp = II_e(:,:,i);
        temp = temp';
        temp(:,1:M) = temp(:,PL(:,i));
        temp = temp';
        temp(:,1:N) = temp(:,PR(:,i));
        temp = bitxor(temp,K_matrix);
        II_d(:,:,i) = temp;        
    end
else
    II_d = II_d';
    II_d(:,1:M) = II_d(:,PL);
    II_d = II_d';
    II_d(:,1:N) = II_d(:,PR);
    II_d = bitxor(II_d,K_matrix);
end
I_re = Reg_re(II_d,x,y,Wide_R,Wide_C,Region_dec);

%show
I_rergb = ycbcr2rgb(I_re);
figure;
imshow(I_rergb);
imwrite(I_rergb,'w.png');
% figure;
% imshow(I_rergb);


%Watermark extraction
W_userex = watermark_extract(I_rergb,Wide_R,Wide_C,emb_loc,num_region,th);
W_encode(64) = [];
W_userex(64) = [];
W_userd = BCH_decode( W_userex', W_encode, kk, t, a );


