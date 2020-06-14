import argparse

import yaml
from tensorflow import keras

from data_utils import data_utils


def main(args):
    with open(args.config, "r+") as f:
        configs = yaml.load(f)

    conf_d = "/".join(args.config.split("/")[:-1])

    if args.test:
        pd_data = data_utils.load_csv_test(args.input, configs['delimiter'])
    else:
        pd_data = data_utils.load_csv(args.input, configs['delimiter'])

    # 前処理
    pd_data = data_utils.preprocessing_pred_data(pd_data, configs, conf_d)

    target_column = configs['target_column']['name']
    columns_be_used = pd_data.columns.tolist()
    if target_column in columns_be_used:
        columns_be_used.remove(target_column)
        y_t = pd_data[target_column].astype(float).values

    X_t = pd_data[columns_be_used].astype(int).values

    with open(conf_d + "/model.yaml", 'r') as f:
        model_yaml = f.read()
    model = keras.models.model_from_yaml(model_yaml)
    model.summary()

    if args.weight == 'model_weights.hdf5':
        model.load_weights(conf_d + '/' + args.weight)
    else:
        model.load_weights(args.weight)

    X_t = [X_t[:, i] for i in range(X_t.shape[1])]
    outcome = model.predict(X_t, batch_size=1024 * 8)

    data_utils.save_pred_data(y_t, outcome, conf_d, 'pred_results')


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', '--input', required=True)
    parser.add_argument('-c', '--config', required=True)
    parser.add_argument('-w', '--weight', default='model_weights.hdf5')
    parser.add_argument('--test', action='store_true')
    args = parser.parse_args()
    main(args)
