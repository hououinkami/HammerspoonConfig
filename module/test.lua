modal = hs.hotkey.modal.new({}, "F19")
modal:bind({}, "a", function()
    print("123a")
    modal:exit() -- remove if this shouldn't clear the modal toggle
end)
modal:bind({}, "b", function()
    print("123b")
    modal:exit() -- remove if this shouldn't clear the modal toggle
end)
modal:bind({}, "F19", function() -- second press leaves modal
    modal:exit()
end)