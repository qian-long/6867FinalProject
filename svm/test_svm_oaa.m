% models is 10 one against all svm classifiers
% winner takes all classification
function[test_error, errors, classifications] = test_svm_oaa(models, feature_extraction_handle)

% representative_feature
top_k_clusters = 5;
num_clusters = 10;

% representative_features_topbot 
topcutoff = 3;
botcutoff = 3;
topbot_numclusters = 15;
obs = [];

path = '~/courses/fall13/6.867/project/test_data/';
lang = {'de';'dutch';'el';'english';'es';'french';'he';'italian';'portuguese';'russian'};
initial_filename = [2000, 2000, 658, 2000, 2000, 2000, 200, 2000, 1991, 700];
max_test_sizes = [1000, 1000, 219, 1000, 1000, 1000, 67, 1000, 663, 223];
test_sizes = zeros(10,1);
for i=1:length(lang)
  test_sizes(i,1) = min(100, max_test_sizes(i));
end

num_wrong = 0;
errors = zeros(length(lang), 1);
% shows svm classification for each lang
% row = target language, col = classifications
% 11 is for other
classifications = zeros(11,11);

for i=1:length(lang)
  num_tests = test_sizes(i);
  % randomly chooses num_tests test cases for current language
  % randomly permute max_test_sizes, select test_sizes filenames
  perm = randperm(max_test_sizes(i), test_sizes(i)); 
  for j=1:num_tests;
    file_num = perm(j) + initial_filename(i);
    filepath = char(strcat(path,lang(i),'_test_files/',lang(i),'-',num2str(file_num), '.wav'));

    try

      % different feature vectors 
      if strcmp(func2str(feature_extraction_handle),'representative_features') == 1 
        features = feature_extraction_handle(filepath, top_k_clusters, num_clusters);
      elseif strcmp(func2str(feature_extraction_handle), 'representative_features_topbot') == 1
        features = feature_extraction_handle(filepath, topcutoff, botcutoff, topbot_numclusters);
      else 
      end

      [output, votes] = get_prediction_oaa(models, transpose(features));

    catch err
      output = 0;
      votes = [];
    end

    if output ~= i
      num_wrong = num_wrong + 1;
      errors(i) = errors(i) + 1;
    end
    
    if output == 0
      classifications(i, 11) = classifications(i, 11) + 1;
    else
      classifications(i, output) = classifications(i, output) + 1;
    end
  end
  
  % error per language
  errors(i) = errors(i) / num_tests;
  display(sprintf('Error for %s: %s', lang{i}, num2str(errors(i))));
end 

% total error
test_error = num_wrong / sum(test_sizes);

end


% obs: row vector
function[output, votes, classifications] = get_prediction_oaa(models, obs)
votes = zeros(10,1);
for i=1:length(models)
  model = models{i};
  prediction = svmclassify(model, obs);

  % not classified as "other"
  if prediction ~= 0
    votes(i) = compute_distance(model, obs);
  end
end

[max_val, max_arg] = max(votes);
output = max_arg;
end

% computes svm function output
function[distance] = compute_distance(model, obs)
sv = model.SupportVectors;
alphas = model.Alpha;
% theta_0
bias = model.Bias;
kfunc_handle = model.KernelFunction;
kfunc_args = model.KernelFunctionArgs;

distance = 0;
for j=1:size(sv,1);
  term = alphas(j) * feval(kfunc_handle, sv(j,:), obs, kfunc_args{:});
  distance = distance + term;
end
distance = abs(distance + bias);
end
