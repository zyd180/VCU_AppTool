function fig = vcu_app()
% vcu_app VCU工具主界面（uifigure，7页签；控件只摆，逻辑在callbacks/与后端）
%   用法: vcu_app
uiDir = fileparts(mfilename('fullpath'));
rootDir = fileparts(uiDir);
addpath(genpath(rootDir));

fig = uifigure('Name', 'VCU AppTool', 'Position', [200 100 900 650]);
fig.UserData.rootDir = rootDir;

% 顶栏：SWC选择 + 刷新
hdr = uipanel(fig, 'Position', [0 600 900 50], 'BorderType', 'none');
uilabel(hdr, 'Text', 'SWC:', 'Position', [10 12 40 22]);
dd = uidropdown(hdr, 'Tag', 'SWCDrop', 'Position', [50 10 200 26]);
uibutton(hdr, 'Text', '刷新', 'Position', [260 10 70 26], ...
    'ButtonPushedFcn', @(s,e) refreshSwc(fig));
uilabel(hdr, 'Tag', 'VerLabel', 'Position', [700 12 190 22], 'HorizontalAlignment', 'right');

% 7页签
tg = uitabgroup(fig, 'Position', [0 130 900 470]);
pages = {'新建','字典','建模','生成','需求','测试','关于'};
tabs = struct();
for k = 1:numel(pages)
    tabs.(sprintf('t%d',k)) = uitab(tg, 'Title', pages{k});
end
buildNewTab(tabs.t1, fig);
buildDictTab(tabs.t2, fig);
buildModelTab(tabs.t3, fig);
buildGenTab(tabs.t4, fig);
buildReqTab(tabs.t5, fig);
buildTestTab(tabs.t6, fig);
buildAboutTab(tabs.t7, fig);

% 底部日志
uilabel(fig, 'Text', '日志', 'Position', [10 108 40 22]);
uitextarea(fig, 'Tag', 'VCULog', 'Position', [10 10 880 95], 'Editable', 'off');

refreshSwc(fig);
fillAbout(fig);
vcu_log(fig, 'VCU AppTool就绪');

    function refreshSwc(fig)
        dd = findobj(fig, 'Tag', 'SWCDrop');
        dd.Items = vcu_swc_list(fig.UserData.rootDir);
        if ~isempty(dd.Items), dd.Value = dd.Items{1}; end
        vcu_log(fig, sprintf('SWC列表已刷新（%d个）', numel(dd.Items)));
    end

    function fillAbout(fig)
        try ver_ = strtrim(fileread(fullfile(fig.UserData.rootDir, 'VERSION'))); catch, ver_ = 'unknown'; end
        vl = findobj(fig, 'Tag', 'VerLabel'); vl.Text = ['v' ver_];
        ta = findobj(fig, 'Tag', 'AboutText');
        req = {'MATLAB','Simulink','AUTOSAR Blockset','Embedded Coder','Simulink Test','Simulink Coverage','Requirements Toolbox'};
        have = {ver().Name};
        lines = {['工具版本: v' ver_], ''};
        for k = 1:numel(req)
            if any(strcmp(have, req{k})), st = 'OK'; else, st = 'MISS'; end
            lines{end+1} = sprintf('[%s] %s', st, req{k}); %#ok<AGROW>
        end
        ta.Value = lines;
    end
end

function mkbtn(parent, txt, pos, fig, cb, arg)
if nargin < 6, arg = []; end
if isempty(arg)
    uibutton(parent, 'Text', txt, 'Position', pos, 'ButtonPushedFcn', @(s,e) cb(fig));
else
    uibutton(parent, 'Text', txt, 'Position', pos, 'ButtonPushedFcn', @(s,e) cb(fig, arg));
end
end

function buildNewTab(t, fig)
uilabel(t, 'Text', '新SWC名:', 'Position', [20 380 70 22]);
uieditfield(t, 'Tag', 'NewSwcName', 'Position', [95 378 180 26], 'Value', 'MySwc');
mkbtn(t, '新建SWC', [285 378 100 26], fig, @cb_new_swc);
uilabel(t, 'Text', '生成字典+模板模型+需求骨架（等价 new_swc）', 'Position', [20 340 500 22]);
end

function buildDictTab(t, fig)
mkbtn(t, '打开字典Excel', [20 378 120 26], fig, @cb_dd, 'open');
mkbtn(t, '转.m', [150 378 80 26], fig, @cb_dd, 'gen');
mkbtn(t, '检查', [240 378 80 26], fig, @cb_dd, 'check');
end

function buildModelTab(t, fig)
mkbtn(t, '打开模型', [20 378 100 26], fig, @cb_model, 'open');
mkbtn(t, '应用全部映射', [130 378 120 26], fig, @cb_model, 'apply');
end

function buildGenTab(t, fig)
mkbtn(t, '一键代码', [20 378 100 26], fig, @cb_gen);
mkbtn(t, 'ARXML', [130 378 80 26], fig, @cb_arxml);
mkbtn(t, 'A2L', [220 378 80 26], fig, @cb_cal);
uilabel(t, 'Text', 'ELF路径（可选，填则解析真实地址）:', 'Position', [20 340 230 22]);
uieditfield(t, 'Tag', 'ElfPath', 'Position', [255 338 400 26]);
end

function buildReqTab(t, fig)
mkbtn(t, '生成骨架', [20 378 100 26], fig, @cb_req, 'gen');
mkbtn(t, '链接', [130 378 80 26], fig, @cb_req, 'link');
mkbtn(t, '检查', [220 378 80 26], fig, @cb_req, 'check');
mkbtn(t, '报告', [310 378 80 26], fig, @cb_req, 'report');
end

function buildTestTab(t, fig)
mkbtn(t, 'Harness', [20 378 100 26], fig, @cb_test, 'harness');
mkbtn(t, '覆盖率快跑', [130 378 100 26], fig, @cb_test, 'run');
end

function buildAboutTab(t, fig)
uitextarea(t, 'Tag', 'AboutText', 'Position', [20 20 840 400], 'Editable', 'off');
end
