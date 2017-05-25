function [dataN]=normalizep(data)
baseline=mean(data);
variance=std(data);
dataN=bsxfun(@rdivide,bsxfun(@minus,data,baseline),variance);
end %function end
