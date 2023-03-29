import yaml
import os
import requests
import argparse

def get_yaml_data(yaml_path):
    # 打开yaml文件
    file = open(yaml_path, 'r', encoding="utf-8")
    file_data = file.read()
    file.close()
    data = yaml.load(file_data, Loader=yaml.SafeLoader)
    return data


def get_yaml(url):
    if not url :
        return {}
    headers = {'User-Agent': 'ClashforWindows/0.18.6'}
    try:
        response = requests.request("GET", url, headers=headers)
        response.raise_for_status() # 检查是否出现请求错误
        return yaml.load(response.text, Loader=yaml.SafeLoader)
    except (requests.exceptions.RequestException, yaml.YAMLError):
        # 如果请求失败或解析YAML出错，返回空字典
        return {}


def update_target_yaml(yaml_target, new_yaml, backup_yaml):
    yaml_target['proxies'] = new_yaml['proxies']
    default_nodes = [item['name'] for item in new_yaml['proxies']]
    default_nodes.insert(0, 'DIRECT')
    if backup_yaml:
        backup_nodes =  [item['name'] for item in backup_yaml['proxies']]
        yaml_target['proxies'].extend(backup_yaml['proxies'])
    else:
        backup_nodes = []
    proxy_groups = yaml_target['proxy-groups']
    proxyselect = {}
    for item in proxy_groups:
        proxyselect[item['name']] = item
    proxyselect['🔰国外流量']['proxies'] = default_nodes
    proxyselect['🔯故障转移']['proxies'] = backup_nodes
    



def save_target_yaml(target_path, target_yaml):
    with open(target_path, 'w', encoding="utf-8") as f:
        yaml.dump(target_yaml, f, indent=2, allow_unicode=True)



def main(subscribe,subscribe_backup):
    file_tpl = "config_tpl.yaml"
    yaml_easynet = get_yaml(subscribe)
    yaml_mojie = get_yaml(subscribe_backup)
    yaml_target = get_yaml_data(file_tpl)
    update_target_yaml(yaml_target,yaml_easynet,yaml_mojie)
    save_target_yaml("config.yaml", yaml_target)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Update configuration file with new server URLs.')
    parser.add_argument('--sub', dest='subscribe', type=str, help='URL of subscription for easynet', required=True)
    parser.add_argument('--bak', dest='subscribe_backup', type=str, help='URL of subscription for mojie')
    args = parser.parse_args()
    main(args.subscribe, args.subscribe_backup)