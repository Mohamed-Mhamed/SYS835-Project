function output = run_rnnoise_reference(inputFile, outputFile, executable)
if ispc
    command = sprintf('wsl.exe "%s" "%s" "%s"', ...
        to_wsl(executable), to_wsl(inputFile), to_wsl(outputFile));
else
    command = sprintf('"%s" "%s" "%s"', executable, inputFile, outputFile);
end
[status, text] = system(command);
if status ~= 0
    error('RNNoise failed (%d): %s', status, text);
end
if ~isfile(outputFile)
    error('RNNoise output was not created: %s', outputFile);
end
info = dir(outputFile);
if info.bytes == 0
    error('RNNoise output is empty: %s', outputFile);
end
output = struct('Command', command, 'Status', status, 'Message', text);
end

function path = to_wsl(pathWindows)
pathWindows = char(pathWindows);
if length(pathWindows) < 3 || pathWindows(2) ~= ':'
    error('Expected an absolute Windows path: %s', pathWindows);
end
path = ['/mnt/' lower(pathWindows(1)) strrep(pathWindows(3:end), '\', '/')];
end
