% the aim of this script is to find a good weighting for the basis
% functions, given that we know the ground truth mask.

cd ~/projects/shape_sharing/2D/src
clear
run ../define_params
addpath predict
addpath utils
addpath external/
addpath external/hist2
addpath external/findfirst
addpath external/libicp/matlab

%% loading in model and test data
load(paths.test_data, 'test_data')
load(paths.structured_predict_si_model_path, 'model');

%% 
clf
num = 35;
params.num_proposals = 12;
params.apply_known_mask = 0;

depth = test_data.depths{num};
segments = test_data.segments{num};
gt_image = test_data.images{num};

transforms = propose_transforms(model, depth, params);
% [out_img, out_img_cropped, transformed] = ...
% aggregate_masks(transforms, params.im_min_height, depth, params);

% plot_transforms(transformed, out_img_cropped, gt_image);

%% now am going to try to get proposals from each of the segments

clf
num = 34;
params.num_proposals = 10;
params.apply_known_mask = 0;
params.transform_type = 'pca';

depth = test_data.depths{num};
segments = test_data.segments{num};
gt_image = test_data.images{num};

transforms = propose_segmented_transforms(model, depth, segments, params);

[out_img, out_img_cropped, transformed] = ...
    aggregate_masks(transforms, params.im_min_height, depth, params);

clf
plot_transforms(transformed, out_img_cropped, gt_image);

%% Here will try to optimise for the weights
% want to find the weights that minimise the sum of squared errors over the
% hidden part of the image
gt_img = single(test_data.images{num});
mask_stack = single(cell2mat(reshape({transformed.cropped_mask}, 1, 1, [])));
[weights, other] = find_optimal_weights(depth, mask_stack, gt_img);

%%

subplot(121)
imagesc(gt_img(1:other.height, :))
axis image

subplot(122)
imagesc(other.final_image)
axis image
set(gca, 'clim', [0, 1])
colormap(gray)


%%
% full image = 2.27
% part image = 0.706



%%
clf
[X, Y] = find(edge(test_data.images{num}));
x_loc = 0;%transformed(1).padding;
y_loc = 0;%transformed(1).padding;
xy = apply_transformation_2d([X'; Y'], [1, 0, y_loc; 0, 1, x_loc; 0 0 1]);

imagesc(out_img_cropped);
hold on
plot(xy(2, :), xy(1, :), 'r+')
hold off
colormap(flipgray)
%set(gca, 'clim', [0, 1])
axis image





%%
params.aggregating = 1;
num = 144
for ii = 1:3
    subplot(1, 4,ii); 
    combine_mask_and_depth(test_data.images{num}, test_data.depths{num})
    width = length(test_data.depths{num})
    set(gca, 'xlim', round([-width/2, 2.5*width]));
    set(gca, 'ylim',round([-width/2, 2.5*width]));
end

stacked_image = test_fitting_model(model, test_data.depths{num}, params);
subplot(1, 4, 4);
imagesc(stacked_image); axis image