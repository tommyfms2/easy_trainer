import csv
import yaml

import numpy as np
import pandas as pd
from sklearn.preprocessing import LabelEncoder
import tqdm


def load_data(args):
    print('### loading data...')
    train = []
    label = []
    delimiters = {'tab': '\t', 'comma': ','}
    with open(args.input_file, 'r') as f:
        reader = csv.reader(f, delimiter=delimiters[args.delimiter])
        header = next(reader)
        idx = header.index(args.target_column)
        i = 0
        for row in reader:
            i += 1
            if i > args.load_lines:
                break
            train.append(row[:idx] + row[idx + 1:])
            label.append(row[idx])

    return train, label


def load_csv(filepath, sep):
    print("### loading data...")
    delimiters = {'tab': '\t', 'comma': ','}
    return pd.read_csv(filepath, sep=delimiters[sep], dtype='str', engine='python', error_bad_lines=False)


def load_csv_test(filepath, sep):
    print("### [TEST MODE] loading data...")
    rows = []
    delimiters = {'tab': '\t', 'comma': ','}
    with open(filepath, 'r') as f:
        reader = csv.reader(f, delimiter=delimiters[sep])
        header = next(reader)
        i = 0
        for row in reader:
            i += 1
            if i > 200:
                break
            rows.append(row)

    return pd.DataFrame(rows, columns=header)


def pd_load_data(args):
    print('### loading data...')
    train = []
    delimiters = {'tab': '\t', 'comma': ','}
    with open(args.input_file, 'r') as f:
        reader = csv.reader(f, delimiter=delimiters[args.delimiter])
        header = next(reader)
        i = 0
        if args.target_column is not None:
            idx = header.index(args.target_column)
        ignore_idxes = []
        if args.ignore_columns is not None:
            ignore_columns = args.ignore_columns.split(',')
            ignore_idxes = [header.index(i) for i in ignore_columns]
            ignore_idxes.sort()
        for row in reader:
            if args.target_column is not None:
                row[idx] = float(row[idx])
            if args.load_lines != -1:
                i += 1
                if i > args.load_lines:
                    break
            for ii, ig_idx in enumerate(ignore_idxes):
                row.remove(row[ig_idx - ii])
            train.append(row)

    pd_data = pd.DataFrame(train, columns=header)

    return pd_data


def save_pred_data(X_t, index_columns, outcome, saveinpath, savefilename):
    if index_columns == '':
        submission = pd.Series(outcome.reshape(-1))
    else:
        submission = pd.DataFrame(columns=index_columns.split(',') + ['outcome'])
        for idx in index_columns.split(','):
            submission[idx] = X_t[idx]
        submission['outcome'] = outcome

    if saveinpath[-1] is not '/':
        saveinpath = saveinpath + '/'
    submission.to_csv(saveinpath + savefilename + '.csv', index=False)
    print('saved result file.')


def preprocessing_train_data(pd_data, configs):
    target_column = configs['target_column']['name']
    columns_be_used = [target_column]
    for origin_column in configs['train_columns']:
        columns_be_used.append(origin_column['name'])

    # conf.ymlに無いcolumnの列を削除
    column_list = pd_data.columns.tolist()
    for c in column_list:
        if not c in columns_be_used:
            del pd_data[c]

    # 問題のあるデータを弾く
    # targetがNanのものを排除
    pd_data = pd_data[~pd_data[target_column].str.match('nan')]
    pd_data = pd_data[~(pd_data[target_column] == '')]
    pd_data = pd_data[~pd_data[target_column].isnull()]

    # text_encoderだけ、先に文字のラベルづけを行う。
    charas = {}
    for origin_column in configs['train_columns']:
        if origin_column['encoder_type'] == "text_encoder":
            for si in range(origin_column['max_length']):
                charas = set(list(charas) + pd_data[origin_column['name']].str[si].dropna(how='all').values.tolist())

    charas = set(list(charas) + ['nan'])
    charas_num_n = len(charas)
    dict_cahras_idx = dict(zip(charas, range(charas_num_n)))

    input_max_nums = {}  # 削除したい
    label_encoder_config = {'encoder_dict': {}}

    for origin_column in tqdm.tqdm(configs['train_columns']):
        column_encode_hist = {}
        if origin_column['encoder_type'] == "date":
            df_date = pd_data[origin_column['name']].str.split('-', expand=True)
            tmp_year = origin_column['name'] + '_year'
            tmp_month = origin_column['name'] + '_month'
            tmp_day = origin_column['name'] + '_day'
            df_date = df_date.rename(
                columns={0: tmp_year, 1: tmp_month, 2: tmp_day})
            pd_data = pd.concat([df_date, pd_data], axis=1)
            del df_date
            pd_data[tmp_year] = pd_data[tmp_year].fillna('2000').str.replace('nan', '2000').replace('', '2000').astype(
                int) - 2000
            pd_data[tmp_year][pd_data[tmp_year] < 0] = 0
            pd_data[tmp_year][pd_data[tmp_year] > 30] = 30
            input_max_nums[tmp_year] = 30
            pd_data[tmp_month] = pd_data[tmp_month].fillna(0).astype(int)
            input_max_nums[tmp_month] = 12 + 1
            pd_data[tmp_day] = pd_data[tmp_day].fillna(0).astype(int)
            input_max_nums[tmp_day] = 31 + 1
            del pd_data[origin_column['name']]

        elif origin_column['encoder_type'] == "label_encoder":
            origin_values = pd_data[origin_column['name']].fillna('null').values.tolist()
            pd_data[origin_column['name']] = LabelEncoder().fit_transform(origin_values)
            num_n = len(set(pd_data[origin_column['name']]))
            input_max_nums[origin_column['name']] = num_n + 1
            column_encode_hist['mapping'] = \
                dict(zip(['nan'] + origin_values, [num_n] + pd_data[origin_column['name']].values.tolist()))
            del origin_values

        elif origin_column['encoder_type'] == "as_label":
            tmp_data = pd_data[origin_column['name']].fillna('0.0')
            tmp_data[tmp_data == ''] = '0.0'
            tmp_data[tmp_data == 'nan'] = '0.0'
            tmp_data = tmp_data.astype(float)
            num_n = tmp_data.max() * float(origin_column['coeff'])
            pd_data[origin_column['name']] = (tmp_data * float(origin_column['coeff'])).fillna(0).astype(int)
            minus_row_flag = pd_data[origin_column['name']] < 0
            if True in minus_row_flag.tolist():
                print('AS_LABEL WARNING: There are some minus values that will be set 0')
                pd_data[origin_column['name']][minus_row_flag] = 0
            input_max_nums[origin_column['name']] = int(num_n) + 1 if not np.isnan(num_n) else 1
            column_encode_hist['max'] = input_max_nums[origin_column['name']]
            del tmp_data

        elif origin_column['encoder_type'] == "text_encoder":
            for si in range(origin_column['max_length']):
                pd_data[origin_column['name'] + str(si)] = \
                    [dict_cahras_idx[x] for x in pd_data[origin_column['name']].str[si].fillna('nan').values.tolist()]
                input_max_nums[origin_column['name'] + str(si)] = charas_num_n + 1
            column_encode_hist['mapping'] = "text_encoded"
            del pd_data[origin_column['name']]

        label_encoder_config['encoder_dict'][origin_column['name']] = column_encode_hist

    label_encoder_config['text_encoded'] = dict_cahras_idx
    label_encoder_config['input_max_nums'] = input_max_nums

    columns_be_used = pd_data.columns.tolist()
    if target_column in columns_be_used:
        columns_be_used.remove(target_column)
    new_input_max_nums = []
    for c in columns_be_used:
        new_input_max_nums.append(input_max_nums[c])

    return pd_data, new_input_max_nums, label_encoder_config


def preprocessing_pred_data(pd_data, configs, conf_d, ignore_target_column=False):
    target_column = configs['target_column']['name']
    columns_be_used = [target_column]
    for origin_column in configs['train_columns']:
        columns_be_used.append(origin_column['name'])

    # conf.ymlに無いcolumnの列を削除
    column_list = pd_data.columns.tolist()
    for c in column_list:
        if not c in columns_be_used:
            del pd_data[c]

    # 問題のあるデータを弾く
    # targetがNanのものを排除
    if not ignore_target_column:
        pd_data = pd_data[~pd_data[target_column].str.match('nan')]
        pd_data = pd_data[~(pd_data[target_column] == '')]
        pd_data = pd_data[~pd_data[target_column].isnull()]

    with open(conf_d + "/label_encoder_config.yml", 'r') as f:
        encoder_map = yaml.load(f)

    for origin_column in tqdm.tqdm(configs['train_columns']):
        try:
            if origin_column['encoder_type'] == "date":
                df_date = pd_data[origin_column['name']].str.split('-', expand=True)
                tmp_year = origin_column['name'] + '_year'
                tmp_month = origin_column['name'] + '_month'
                tmp_day = origin_column['name'] + '_day'
                df_date = df_date.rename(
                    columns={0: tmp_year, 1: tmp_month, 2: tmp_day})
                pd_data = pd.concat([df_date, pd_data], axis=1)
                del df_date
                pd_data[tmp_year] = pd_data[tmp_year].fillna('2000').str.replace('nan', '2000').replace('',
                                                                                                        '2000').astype(
                    int) - 2000
                pd_data[tmp_year][pd_data[tmp_year] < 0] = 0
                pd_data[tmp_year][pd_data[tmp_year] > 30] = 30
                pd_data[tmp_month] = pd_data[tmp_month].fillna(0).astype(int)
                pd_data[tmp_day] = pd_data[tmp_day].fillna(0).astype(int)
                del pd_data[origin_column['name']]

            elif origin_column['encoder_type'] == "label_encoder":
                origin_values = pd_data[origin_column['name']].values.tolist()
                col_encoder_map = encoder_map['encoder_dict'][origin_column['name']]['mapping']
                pd_data[origin_column['name']] = [col_encoder_map[x]
                                                  if x in col_encoder_map else col_encoder_map['nan'] for x in
                                                  origin_values]
                del origin_values

            elif origin_column['encoder_type'] == "as_label":
                tmp_data = pd_data[origin_column['name']].fillna('0.0')
                tmp_data[tmp_data == ''] = '0.0'
                tmp_data[tmp_data == 'nan'] = '0.0'
                tmp_data = tmp_data.astype(float)
                # tmp_data = pd_data[origin_column['name']].fillna('0.0').str.replace('nan', '0.0').astype(float)
                label_max = int(encoder_map['encoder_dict'][origin_column['name']]['max'])
                tmp_data = (tmp_data * float(origin_column['coeff'])).fillna(0).astype(int)
                tmp_data[tmp_data >= label_max] = label_max - 1
                pd_data[origin_column['name']] = tmp_data
                del tmp_data

            elif origin_column['encoder_type'] == "text_encoder":
                col_encoder_map = encoder_map['text_encoded']
                for si in range(origin_column['max_length']):
                    pd_data[origin_column['name'] + str(si)] = \
                        [col_encoder_map[x] if x in col_encoder_map else col_encoder_map['nan']
                         for x in pd_data[origin_column['name']].str[si].fillna('nan').values.tolist()]
                del col_encoder_map
                del pd_data[origin_column['name']]

        except Exception as e:
            # なぞにカラムが無いときもしくは最適化するために無いときは適当な値いれちゃう
            if origin_column['encoder_type'] == "date":
                tmp_year = origin_column['name'] + '_year'
                tmp_month = origin_column['name'] + '_month'
                tmp_day = origin_column['name'] + '_day'
                pd_data[tmp_year][pd_data[tmp_year] > 30] = 20
                pd_data[tmp_month] = 1
                pd_data[tmp_day] = 1
            elif origin_column['encoder_type'] == "label_encoder":
                col_encoder_map = encoder_map['encoder_dict'][origin_column['name']]['mapping']
                pd_data[origin_column['name']] = col_encoder_map['nan']
            elif origin_column['encoder_type'] == "as_label":
                pd_data[origin_column['name']] = 0
            elif origin_column['encoder_type'] == "text_encoder":
                col_encoder_map = encoder_map['text_encoded']
                for si in range(origin_column['max_length']):
                    pd_data[origin_column['name'] + str(si)] = col_encoder_map['nan']

    return pd_data


def modify_as_label_column_to_x(pd_data, configs, conf_d, column, x):
    with open(conf_d + "/label_encoder_config.yml", 'r') as f:
        encoder_map = yaml.load(f)

    for origin_column in configs['train_columns']:
        if origin_column['name'] == column:
            break

    newX = int(x * float(origin_column['coeff']))
    label_max = int(encoder_map['encoder_dict'][origin_column['name']]['max'])

    # print('origin_column_name: ', origin_column['name'], 'newX: ', str(newX), ', label_max: ', str(label_max))
    over = False
    if newX >= label_max:
        print('The value of x: ', x, " is greater than prediction model max setting.")
        newX = label_max - 1
        over = True
    pd_data[column] = newX

    return pd_data, over
