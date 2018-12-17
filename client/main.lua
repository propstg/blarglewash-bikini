RegisterCommand('wash2', function (source, args)
    TriggerEvent('chatMessage', source, "test", "test")
    Wash.DoWash()
end, false)
