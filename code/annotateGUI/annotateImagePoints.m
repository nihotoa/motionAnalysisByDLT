%{
[input arguments]
key_point_num: [double], キャリブレーションフレームのキーポイントの数(太田が作ったフレームを使用しているのであれば12)
image_file_path_list: [cell array],  使用する画像ファイルのパスが格納されたセル配列

[output arguments]
image_coordinates_list: [double array], 各キーポイントの画像座標が格納されたdouble配列.

[improvement point]
UIがクソ: 
    > 誘導がわかりにくい
    > アノテーション時に画像のzoom, panができない(アノテーションのためのクリックイベントとzoomのためのクリックイベントがコンフリクトしてしまうため、zoomとpanを途中でoffにした)
    > アノテーションの位置が修正できない(実装するのが手間だと思ったから着手してない)
%}

function [image_coordinates_list] = annotateImagePoints(key_point_num, image_file_path_list)
point_names = arrayfun(@(k) sprintf('P%d', k), 1:key_point_num, 'UniformOutput', false);
colors = lines(key_point_num); % keypointに対応する色の生成
cam_num = length(image_file_path_list);
image_coordinates_list = cell(1, cam_num);

for cam_id = 1:cam_num
    % 画像座標を格納するための配列
    selected_image_coordinates = zeros(key_point_num, 2);

    % 対応するカメラ画像にアノテーションする
    while true
        % 画像の読み込みと表示
        image = imread(image_file_path_list{cam_id});
        fig = figure();
        imshow(image);
        hold on;

        % zoomとpanの設定
        zoom on;
        pan on;
        disp('ズームと移動によってアノテーションしやすい位置に変更してください。(アノテーション中はズームできません).完了したらEnterを押してください')
        pause;
        pan off;
        zoom off;

        % キーポイントごとにアノテーション
        disp(['-------------------- camera' num2str(cam_id) 'のアノテーションを開始します --------------------'])
        for key_point_id = 1:key_point_num
            disp(['     P' num2str(key_point_id) 'を左クリックで選択してください(写っていない場合は"s"を, 途中で終了する場合は"q"を押してください)'])

            % 現在のfigure内側でのイベントのキャッチ(クリックされたら0, キーが押されたら1を返す関数)
            w = waitforbuttonpress;
            if w == 0 
                % 座標を格納
                mousePos = get(gca, 'Currentpoint');
                x = mousePos(1, 1);
                y = mousePos(1, 2);
                selected_image_coordinates(key_point_id, :) = [x, y];

                % 選択した点を画像上に表示
                plot(x, y, 'o', 'MarkerSize', 5, 'MarkerEdgeColor', colors(key_point_id, :), 'MarkerFaceColor', colors(key_point_id, :));
                text(x + 10, y, point_names{key_point_id}, 'Color', colors(key_point_id, :), 'FontSize', 10);

            elseif w == 1
                % sを押したらスキップ、qを押したらアノテーションを途中で終了
                key = get(gcf, 'CurrentKey');
                if strcmp(key, 's')
                    continue;
                elseif strcmp(key, 'q')
                    disp('処理を中止しました')
                    break;
                end
            end
        end
        hold off;
        disp('-------------------- アノテーションを終了しました --------------------')
        
        % figオブジェクトにキーイベントに対するコールバックを設定。(この前に適用するとwaitforbuttonpressとコンフリクトするのでここで定義)
        global pressed_key
        pressed_key = '';
        set(fig, 'WindowKeyPressFcn', @trashJudgeCallback)

        disp('アノテーションが問題ない場合はEnterを、やり直す場合はその他のキーを押してください')
        uiwait(fig);
    
        % 押されたキーによってその後の処理を条件分岐
        if strcmp(pressed_key, 'return')
            image_coordinates_list{cam_id} = selected_image_coordinates;
            close all;
            disp(['Enterが押されました。camera' num2str(cam_id) 'の画像座標が適切に保存されました。'])
            break;
        else
            disp(['その他のキーが押されました、もう一度cameara' num2str(cam_id) 'のアノテーションを最初からやり直してください'])
            disp('-----------------------------------------------------------------')
            close all;
        end
    end
end

% image_coordinates_listをdouble配列に変換
image_coordinates_list = cell2mat(image_coordinates_list);
end

