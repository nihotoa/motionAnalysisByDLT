function max_amplitude = getMaxAmplitudeGUI(ref_body_parts_displacements)
while true
    disp('Please select the top ot the spike')
    plot(ref_body_parts_displacements)
    datacursormode on
    dlg = warndlg("Please push 'OK' after export 'cursor_info'");
    uiwait(dlg)
    close all;
    try
        cursor_info = evalin("base", 'cursor_info');
        max_amplitude = cursor_info.Position(2);
    catch
        disp("'cursor_info' is not output. Please try again")
        continue
    end
    clear cursor_info
    break
end
end