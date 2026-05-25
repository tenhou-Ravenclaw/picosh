$val = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes('waiting'))
[Console]::Write([char]27 + "]1337;SetUserVar=picosh_waiting=$val" + [char]7)
