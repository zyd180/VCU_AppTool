function [swc, rootDir] = vcu_cur(fig)
% vcu_cur 取当前SWC+根目录（回调统一入口，空下拉直接报错）
dd = findobj(fig, 'Tag', 'SWCDrop');
assert(~isempty(dd.Items), '无SWC，先新建');
swc = dd.Value;
if iscell(swc), swc = swc{1}; end
rootDir = fig.UserData.rootDir;
end
