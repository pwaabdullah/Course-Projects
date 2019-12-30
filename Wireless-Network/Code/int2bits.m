function y=int2bits(u)
% Input is uint8's, output is logicals

% y=false(8,length(u));
% for ii=1:length(u)
%     for jj=1:8
%         y(jj,ii) = and(bitand(u(ii),2^(-jj+8)),1);
%     end
% end

y=false(8,length(u));
for ii=1:length(u)
    y(:,ii) = and(bitand(uint8(ones(8,1))*u(ii),uint8([128;64;32;16;8;4;2;1])),1);
end
    