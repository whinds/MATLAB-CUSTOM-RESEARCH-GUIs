function d = eud(x,y)
%euclidian distance
d = sum(bsxfun(@minus,x,y).^2,2).^0.5;
end