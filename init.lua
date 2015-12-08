local rootDir = (...):gsub('%.init$', '')
if type(jit) == 'table' then
  return require(rootDir .. 'EZControls-compiled-luajit')
else
  return require(rootDir .. 'EZControls')
end
