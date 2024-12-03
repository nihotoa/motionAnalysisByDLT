function [peak_displacement_indices]  = getPeakDisplacementIndices(ref_body_parts_displacements, displacement_threshold)
candidate_index_list = find(ref_body_parts_displacements > displacement_threshold);
stim_start_index_list = eliminate_consective_num(candidate_index_list, 'front');
stim_end_index_list = eliminate_consective_num(candidate_index_list, 'back');
stim_timing_data_list = [stim_start_index_list; stim_end_index_list];
stim_num = size(stim_timing_data_list, 2);

% peak timingのindexを探す
peak_displacement_indices = nan(1, stim_num);
for stim_id = 1:stim_num % trial of stimulations
    ref_stim_timing = stim_timing_data_list(:, stim_id);
    if (ref_stim_timing(1) == ref_stim_timing(2))
        continue
    end
    peak_displacement_indices(stim_id) = find(ref_body_parts_displacements == max(ref_body_parts_displacements(ref_stim_timing(1):ref_stim_timing(2))));
end
end