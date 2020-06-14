import argparse
import os
import shutil
from collections import OrderedDict

import pandas as pd
import yaml


def represent_odict(dumper, instance):
    return dumper.represent_mapping('tag:yaml.org,2002:map', instance.items())


yaml.add_representer(OrderedDict, represent_odict)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-c', '--config_name', required=True)
    parser.add_argument('-i', '--input', required=True)
    parser.add_argument('-t', '--target_column', required=True)
    parser.add_argument('-o', '--output_dir_name', default='outputs')
    parser.add_argument('-d', '--delimiter', default='tab')
    parser.add_argument('-b', '--batch_size', default=8192, type=int)
    parser.add_argument('-de', '--dim_embed', default=64, type=int)
    parser.add_argument('-dh', '--dim_hidden', default=128, type=int)
    parser.add_argument('-e', '--epochs', default=10, type=int)
    parser.add_argument('--force_rebuild', action='store_true')
    args = parser.parse_args()

    if os.path.exists('./configs/' + args.config_name):
        if args.force_rebuild:
            shutil.rmtree('./configs/' + args.config_name)
            print('delete old directory')
        else:
            print('Abort: There is already the directory the name of which is the same as input.')
            return
    os.mkdir('./configs/' + args.config_name)
    print('made ', './configs/' + args.config_name)

    conf = {}
    conf['input_file'] = args.input
    conf['output_dir_name'] = args.output_dir_name
    conf['delimiter'] = args.delimiter
    conf['batch_size'] = args.batch_size
    conf['dim_embed'] = args.dim_embed
    conf['dim_hidden'] = args.dim_hidden
    conf['epochs'] = args.epochs
    conf['target_column'] = {'name': args.target_column, 'type': 'float'}
    conf['train_columns'] = []

    delimiters = {'tab': '\t', 'comma': ','}

    df_data = pd.read_csv(args.input, sep=delimiters[args.delimiter])
    header = df_data.columns.values.tolist()
    for h in header:
        if not h == args.target_column:
            conf_dict = {'name': h}
            if df_data[h].dtype == object:
                if len(set(df_data[h].values)) < len(df_data[h].values) // 10:
                    conf_dict['encoder_type'] = 'label_encoder'
                else:
                    conf_dict['encoder_type'] = 'text_encoder'
                    conf_dict['max_length'] = int(df_data[h].str.len().max())
            elif df_data[h].dtype == int or df_data[h].dtype == float:
                df_min = float(df_data[h].min())
                df_max = float(df_data[h].max())
                if df_min < 0 or df_max >= 1000000:
                    conf_dict['encoder_type'] = 'text_encoder'
                    conf_dict['max_length'] = 10
                elif df_data[h].dtype == int:
                    conf_dict['encoder_type'] = 'as_label'
                    conf_dict['coeff'] = 1
                else:
                    conf_dict['encoder_type'] = 'as_label'
                    if df_max < 1000:
                        conf_dict['coeff'] = 100
                    else:
                        conf_dict['coeff'] = 1

            conf_dict['# appendix'] = \
                'dtype: ' + str(df_data[h].dtype) + \
                ', min: ' + str(df_data[h].dropna().min()) + \
                ', max: ' + str(df_data[h].dropna().max()) + \
                ', unique percent: ' + str(
                    100.0 * len(set(df_data[h].dropna().values)) / len(df_data[h].dropna().values))
            conf['train_columns'].append(conf_dict)

    with open('./configs/' + args.config_name + "/conf.yml", "w") as f:
        yaml.dump(conf, f, encoding='utf-8', allow_unicode=True, default_flow_style=False, sort_keys=False)


if __name__ == "__main__":
    main()
