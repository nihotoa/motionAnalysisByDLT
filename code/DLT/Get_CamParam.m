%{
[role of this function]
キャリブレーションフレームの画像座標と実座標の値を使って、最小2乗法で書くカメラのカメラパラメータを求める

[input arguments]
P_world: [double array], キーポイントの実座標の記録された配列
P_image: [double array], キーポイントの画像座標の記録された配列

[output arguments]
a: [double array], 各カメラのカメラパラメータ。11 * (カメラ数)の配列で、各列ベクトルが各カメラのカメラパラメータに該当
%}

function a = Get_CamParam(P_world, P_image)
% key_pointとcamera_numを算出
[key_point_num, col_num] = size(P_image);
camera_num = col_num / 2;
a = zeros(11, camera_num);

% カメラごとにカメラパラメータを求める
for camera_id = 1 : camera_num
    % t = Maで最小2乗法によってaを求める
    clear m;
    clear t;
    m = cell(key_point_num, 1);
    t = cell(key_point_num, 1);
    for key_point_id = 1 : key_point_num
        ref_P_image = P_image(key_point_id, (2*(camera_id-1)+1) : (2*(camera_id-1)+2));

        % key_pointがの座標値がなかった場合
        if all(ref_P_image) == 0
            continue;
        end

        % 参照する実座標(x, y, z), 画像座標(u, v)を取得
        x = P_world(key_point_id, 1);
        y = P_world(key_point_id, 2);
        z = P_world(key_point_id, 3);

        u = ref_P_image(1);
        v = ref_P_image(2);

        % 画像座標をtに代入
        t{key_point_id} = [u; v];
        
        % 3次元座標をmに代入
        m_element = zeros(2, 11);
        m_element(1, :) = [x, y, z, 1, 0, 0, 0, 0, (-1 * u * x), (-1 * u * y), (-1 * u * z)];
        m_element(2, :) = [0, 0, 0, 0, x, y, z, 1,  (-1 * v * x), (-1 * v * y), (-1 * v * z)];
        m{key_point_id} = m_element;
    end
    % からのセル配列を除去する
    m = m(~cellfun('isempty', m));
    t = t(~cellfun('isempty', t));

    % m, tをdouble配列に変換する
    m = cell2mat(m);
    t = cell2mat(t); 
    
    % 最小二乗法でカメラパラメータを求める(正規方程式)
    a(:, camera_id) = inv(transpose(m) * m) * transpose(m) * t;
end
end
