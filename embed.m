function I_em = embed(I,w,loc_one,loc_two,r)

if loc_one(1) == 4
    l1 = 51;
    l2 = 56;
else
    l1 = 56;
    l2 = 51;
end

I_dct = dct2(I);
C1 = I_dct(loc_one(1),loc_one(2));
C2 = I_dct(loc_two(1),loc_two(2));
if w == 0
    if C1 < C2
        C = C1;
        C1 = C2;
        C2 = C;
    end
else
    if C1 > C2
        C = C1;
        C1 = C2;
        C2 = C;
    end  
end
delta = (5/11424)*(C1*l1+C2*l2) + r * 26.75;
if C1 > C2
    CC1 = C1 + delta;
    CC2 = C2 - delta;
else
    CC1 = C1 - delta;
    CC2 = C2 + delta;     
end
I_dct(loc_one(1),loc_one(2)) = CC1;
I_dct(loc_two(1),loc_two(2)) = CC2;
I_em = idct2(I_dct);
I_em(find(I_em>255)) = 255;
I_em(find(I_em<0)) = 0;
I_em = mod(round(I_em),256);

end
