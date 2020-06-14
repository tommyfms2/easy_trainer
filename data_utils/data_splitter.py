
import argparse
import pandas as pd


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', '--input')
    parser.add_argument('-t', '--threshold_date')
    parser.add_argument('-d', '--delimiter', default='\t')
    parser.add_argument('-y', '--ymd', default='ymd_date')
    args = parser.parse_args()

    df_data = pd.read_csv(args.input, args.delimiter)

    df_data_2_flag = df_data[args.ymd] > args.threshold_date

    df_data_2 = df_data[df_data_2_flag]
    df_data = df_data[~df_data_2_flag]

    df_data.to_csv(args.input+'_before-'+args.threshold_date, sep=args.delimiter, index=False)
    df_data_2.to_csv(args.input+'_after-'+args.threshold_date, sep=args.delimiter, index=False)


if __name__=='__main__':
    main()