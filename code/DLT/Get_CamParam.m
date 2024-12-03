%{
[role of this function]
�L�����u���[�V�����t���[���̉摜���W�Ǝ����W�̒l���g���āA�ŏ�2��@�ŏ����J�����̃J�����p�����[�^�����߂�

[input arguments]
P_world: [double array], �L�[�|�C���g�̎����W�̋L�^���ꂽ�z��
P_image: [double array], �L�[�|�C���g�̉摜���W�̋L�^���ꂽ�z��

[output arguments]
a: [double array], �e�J�����̃J�����p�����[�^�B11 * (�J������)�̔z��ŁA�e��x�N�g�����e�J�����̃J�����p�����[�^�ɊY��
%}

function a = Get_CamParam(P_world, P_image)
% key_point��camera_num���Z�o
[key_point_num, col_num] = size(P_image);
camera_num = col_num / 2;
a = zeros(11, camera_num);

% �J�������ƂɃJ�����p�����[�^�����߂�
for camera_id = 1 : camera_num
    % t = Ma�ōŏ�2��@�ɂ����a�����߂�
    clear m;
    clear t;
    m = cell(key_point_num, 1);
    t = cell(key_point_num, 1);
    for key_point_id = 1 : key_point_num
        ref_P_image = P_image(key_point_id, (2*(camera_id-1)+1) : (2*(camera_id-1)+2));

        % key_point���̍��W�l���Ȃ������ꍇ
        if all(ref_P_image) == 0
            continue;
        end

        % �Q�Ƃ�������W(x, y, z), �摜���W(u, v)���擾
        x = P_world(key_point_id, 1);
        y = P_world(key_point_id, 2);
        z = P_world(key_point_id, 3);

        u = ref_P_image(1);
        v = ref_P_image(2);

        % �摜���W��t�ɑ��
        t{key_point_id} = [u; v];
        
        % 3�������W��m�ɑ��
        m_element = zeros(2, 11);
        m_element(1, :) = [x, y, z, 1, 0, 0, 0, 0, (-1 * u * x), (-1 * u * y), (-1 * u * z)];
        m_element(2, :) = [0, 0, 0, 0, x, y, z, 1,  (-1 * v * x), (-1 * v * y), (-1 * v * z)];
        m{key_point_id} = m_element;
    end
    % ����̃Z���z�����������
    m = m(~cellfun('isempty', m));
    t = t(~cellfun('isempty', t));

    % m, t��double�z��ɕϊ�����
    m = cell2mat(m);
    t = cell2mat(t); 
    
    % �ŏ����@�ŃJ�����p�����[�^�����߂�(���K������)
    a(:, camera_id) = inv(transpose(m) * m) * transpose(m) * t;
end
end
