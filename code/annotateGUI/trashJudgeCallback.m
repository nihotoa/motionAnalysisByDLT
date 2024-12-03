%{
アノテーションが終わった後、キーが押された時に呼び出されるコールバック関数。そのアノテーション結果を採用するかどうかに使われる
コールバック関数は値を返せないらしいので、グローバル変数を使用せざるを得なかった
srcはこのコールバック関数を引数に持つオブジェクト
%}
function trashJudgeCallback(src, event)
    global pressed_key;
    pressed_key = event.Key;
    uiresume(gcf); %uiwaitを解除する
end

