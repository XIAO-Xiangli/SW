function w_ex = extract(I1,loc_x,loc_y,emb_loc,Wide_R,Wide_C)

w_ex = zeros(Wide_R*Wide_C/64,9);
for i = 1:9
    temp = I1(loc_x(i)-Wide_R/2+1:loc_x(i)+Wide_R/2,loc_y(i)-Wide_C/2+1:loc_y(i)+Wide_C/2);
    index = 1;
    for j = 8 : 8 : Wide_R
        for k = 8 : 8 : Wide_C
            if emb_loc(j/8,k/8) == 0
               loc_one = [5,4]; loc_two = [4,5];
            else
               loc_one = [4,5]; loc_two = [5,4]; 
            end
            temp_s = temp(j-7:j,k-7:k);
            temp_s = dct2(temp_s);
            C1 = temp_s(loc_one(1),loc_one(2));
            C2 = temp_s(loc_two(1),loc_two(2));
            if C1 > C2
                w_ex(index,i) = 0;
            else
                w_ex(index,i) = 1;
            end
            index = index + 1;
        end
    end
end

end