#!/usr/bin/env python3

import re
import os
import shutil
import subprocess
from subprocess import Popen
import argparse
from datetime import datetime

# outputs to github env if present
def github_output(name, value):
    if 'GITHUB_OUTPUT' in os.environ:
        with open(os.environ['GITHUB_OUTPUT'], 'a') as env:
            env.write(f'{name}={value}')

changelog_path = 'StagingDev/Changelog.md'

def parse_changelog():
    with open(changelog_path, 'r') as file:
        lines = file.readlines()
        delimeters = [index - 1 for index, value in enumerate(lines) if value == '==============\n']
        delimeters.append(len(lines) + 1)
        return [{
            'tag': lines[index[0]].strip(),
            'date': lines[index[0] + 2].strip(),
            'notes': ''.join(lines[index[0] + 3:index[1]]).strip(),
        } for index in zip(delimeters, delimeters[1:])]

def get_release_notes(args):
    changelog = parse_changelog()
    print(changelog[0]['notes'])

def release_commit(args):
    # TODO perhaps check if index is dirty to avoid clobbering anything

    with open(changelog_path, mode='r') as file:
        lines = file.readlines()
    version = lines[0].strip()
    if lines[2] != 'TBD\n':
        raise Exception('date is not "TBD"')
    lines[2] = datetime.today().strftime('%Y-%m-%d') + '\n'

    with open(changelog_path, mode='w') as file:
        file.writelines(lines)

    message = f'Release {version}'
    subprocess.run(['git', 'add', changelog_path], check=True)
    if args.username:
        subprocess.run(['git', '-c', f'user.name="{args.username}"', '-c', f'user.email="{args.username}@users.noreply.github.com"', 'commit', '-m', message], check=True)
    else:
        subprocess.run(['git', 'commit', '-m', message], check=True)
    subprocess.run(['git', 'tag', version], check=True)

    github_output('release_tag', version)

def build(args):
    # builds a release version of StagingDev by copying the directory and then
    # removing and disabling dev-only settings and files

    release_output = 'release'
    shutil.rmtree(release_output, ignore_errors=True)
    os.mkdir(release_output)

    out_dir = 'StagingRelease'

    def make_staging_release():
        exclude_files = [
            'API.txt',
            'Mods/shared/Types.lua',
            'UE4SS_Signatures',
            'VTableLayoutTemplates',
            'MemberVarLayoutTemplates',
        ]

        settings_to_modify_in_release = {
            'GuiConsoleVisible': 0,
            'ConsoleEnabled': 0,
            'EnableHotReloadSystem': 0,
            'IgnoreEngineAndCoreUObject': 1,
            'MaxMemoryUsageDuringAssetLoading': 80,
        }

        change_modstxt = {
            'LineTraceMod': 0,
        }

        # copy whole directory
        shutil.rmtree(out_dir, ignore_errors=True)
        shutil.copytree('StagingDev/', out_dir)

        # remove files
        for file in exclude_files:
            path = os.path.join(out_dir, file)
            try:
                os.remove(path)
            except:
                shutil.rmtree(path)

        # change UE4SS-settings.ini
        config_path = os.path.join(out_dir, 'UE4SS-settings.ini')

        with open(config_path, mode='r', encoding='utf-8-sig') as file:
            content = file.read()

        for key, value in settings_to_modify_in_release.items():
            pattern = rf'(^{key}\s*=).*?$'
            content = re.sub(pattern, rf'\1 {value}', content, flags=re.MULTILINE)

        with open(config_path, mode='w', encoding='utf-8-sig') as file:
            file.write(content)

        # change Mods/mods.txt
        mods_path = os.path.join(out_dir, 'Mods/mods.txt')

        with open(mods_path, mode='r', encoding='utf-8-sig') as file:
            content = file.read()

        for key, value in change_modstxt.items():
            pattern = rf'(^{key}\s*:).*?$'
            content = re.sub(pattern, rf'\1 {value}', content, flags=re.MULTILINE)

        with open(mods_path, mode='w', encoding='utf-8-sig') as file:
            file.write(content)

    def build_release(target_xinput: bool):
        cmd = 'build_auto.bat Release {}'
        if target_xinput:
            p = Popen(cmd.format('xinput1_3'))
            p.communicate()
        else:
            p = Popen(cmd.format(''))
            p.communicate()

    def package_release(target_xinput: bool, is_dev_release: bool):
        version = subprocess.check_output(['git', 'describe', '--tags']).decode('utf-8').strip()
        main_zip_name = ''
        staging_dir = ''
        if is_dev_release:
            main_zip_name = 'zDEV-UE4SS_{}_{}'.format('Xinput' if target_xinput else 'Standard', version)
            staging_dir = 'StagingDev'
        else:
            main_zip_name = 'UE4SS_{}_{}'.format('Xinput' if target_xinput else 'Standard', version)
            staging_dir = 'StagingRelease'

        bin_name = 'xinput1_3' if target_xinput else 'ue4ss'
        bin_dir = 'Output/ue4ss/Binaries/x64/Release'


        shutil.copyfile('{}/{}.dll'.format(bin_dir, bin_name), '{}/{}.dll'.format(staging_dir, bin_name))

        if is_dev_release:
            shutil.copyfile('{}/{}.pdb'.format(bin_dir, bin_name), '{}/{}.pdb'.format(staging_dir, bin_name))
            if os.path.exists('{}/docs'.format(staging_dir)):
                shutil.copytree('docs/', '{}/docs'.format(staging_dir))

        shutil.make_archive(os.path.join(release_output, main_zip_name), 'zip', staging_dir)

        if os.path.exists('{}/{}.dll'.format(staging_dir, bin_name)):
            os.remove('{}/{}.dll'.format(staging_dir, bin_name))
        if os.path.exists('{}/{}.pdb'.format(staging_dir, bin_name)):
            os.remove('{}/{}.pdb'.format(staging_dir, bin_name))

        if is_dev_release and os.path.exists('{}/docs'.format(staging_dir)):
            shutil.rmtree('{}/docs'.format(staging_dir), ignore_errors=False)


    make_staging_release();

    # Build UE4SS Standard
    build_release(target_xinput = False)
    package_release(target_xinput = False, is_dev_release = False)
    package_release(target_xinput = False, is_dev_release = True)

    # Build UE4SS Xinput
    build_release(target_xinput = True)
    package_release(target_xinput = True, is_dev_release = False)
    package_release(target_xinput = True, is_dev_release = True)

    # CustomGameConfigs
    shutil.make_archive(os.path.join(release_output, 'zCustomGameConfigs'), 'zip', 'CustomGameConfigs')

    # MapGenBP
    shutil.make_archive(os.path.join(release_output, 'zMapGenBP'), 'zip', 'MapGenBP')

    changelog = parse_changelog()
    with open(os.path.join(release_output, 'release_notes.md'), 'w') as file:
        file.write(changelog[0]['notes'])

    print('done')

commands = {f.__name__: f for f in [
    get_release_notes,
    build,
    release_commit,
]}

parser = argparse.ArgumentParser()
subparsers = parser.add_subparsers(dest='command', required=True)
build_parser = subparsers.add_parser('build')
release_commit_parser = subparsers.add_parser('release_commit')
release_commit_parser.add_argument('username', nargs='?')
args = parser.parse_args()

commands[args.command](args)
