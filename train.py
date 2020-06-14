import argparse
import os
import shutil
from collections import OrderedDict

import numpy as np
import yaml
from sklearn.model_selection import KFold
from tensorflow import keras

from data_utils import data_utils
from models import model_embed


def represent_odict(dumper, instance):
    return dumper.represent_mapping('tag:yaml.org,2002:map', instance.items())


yaml.add_representer(OrderedDict, represent_odict)


def main(args):
    # コンフィグとデータのロード
    with open(args.config, "r+") as f:
        configs = yaml.load(f)

    if args.test:
        pd_data = data_utils.load_csv_test(configs['input_file'], configs['delimiter'])
    else:
        pd_data = data_utils.load_csv(configs['input_file'], configs['delimiter'])

    # 前処理
    pd_data, input_max_nums, label_encoder_config = \
        data_utils.preprocessing_train_data(pd_data, configs)

    threshold = pd_data.shape[0] // 10 * 9
    train = pd_data[:threshold]
    test = pd_data[threshold:]
    del pd_data

    target_column = configs['target_column']['name']

    columns_be_used = train.columns.tolist()
    columns_be_used.remove(target_column)
    X = train[columns_be_used].astype(int).values
    X_t = test[columns_be_used].astype(int).values
    y = train[target_column].astype(float).values
    y_t = test[target_column].astype(float).values
    del train
    del test

    seed = 1
    np.random.seed(1)
    skf = KFold(n_splits=5, shuffle=True, random_state=seed)
    for train_index, test_index in skf.split(X, y):
        X_train, X_test = X[train_index], X[test_index]
        y_train, y_test = y[train_index], y[test_index]
        break

    X_train = [X_train[:, i] for i in range(X.shape[1])]
    X_test = [X_test[:, i] for i in range(X.shape[1])]
    del X

    # 予測時に利用するConfigを保存する
    output_d = "/".join(args.config.split("/")[:-1]) + "/" + configs['output_dir_name']

    if os.path.exists(output_d):
        shutil.rmtree(output_d)
    os.mkdir(output_d)

    with open(output_d + "/label_encoder_config.yml", "w", encoding='utf-8') as f:
        yaml.dump(label_encoder_config, f, encoding='utf-8', allow_unicode=True, default_flow_style=False,
                  sort_keys=False)

    with open(output_d + "/conf.yml", "w", encoding='utf-8') as f:
        yaml.dump(configs, f, encoding='utf-8', allow_unicode=True, default_flow_style=False, sort_keys=False)

    # モデル作成
    batch_size = configs["batch_size"]
    epochs = configs["epochs"]

    output_df = output_d + '/snapshots'
    if os.path.exists(output_df):
        shutil.rmtree(output_df)
    os.mkdir(output_df)
    model_f = os.path.join(output_df, 'ss_epoch{epoch:02d}-loss{loss:.3f}-val_loss{val_loss:.3f}.hdf5')
    cb = keras.callbacks.ModelCheckpoint(filepath=model_f, monitor='val_loss', verbose=1, save_best_only=True,
                                         mode='min', period=2)

    model = model_embed.build_model(input_max_nums, configs["dim_embed"], configs["dim_hidden"])

    yaml_string = model.to_yaml()
    open(os.path.join(output_d, 'model.yaml'), 'w').write(yaml_string)

    # 学習
    model.fit(
        X_train,
        y_train,
        batch_size=batch_size,
        epochs=epochs,
        verbose=1,
        shuffle=True,
        validation_data=[X_test, y_test],
        callbacks=[cb]
    )
    print('saving weights')
    model.save_weights(os.path.join(output_d, 'model_weights.hdf5'))

    X_t = [X_t[:, i] for i in range(X_t.shape[1])]
    outcome = model.predict(X_t, batch_size=8192)

    data_utils.save_pred_data(y_t, outcome, output_d, 'train_test_results')


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('-c', '--config', required=True)
    parser.add_argument('--test', action='store_true')
    args = parser.parse_args()

    main(args)
