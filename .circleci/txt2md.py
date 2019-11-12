"""This script generates README.md based on s3_list.txt. If an S3 object's
parent folder(s) doesn't exist, this script will be smart enough to create
the parent folder(s) as separate items in output MD file.
"""

TXT_FILENAME = "processed/s3_list.txt"
MD_FILENAME = "processed/README.md"

def get_md_name(s3_name):
    """Returns the filename with leading bullet list MD format."""

    path_tokens = s3_name.rstrip('/').split('/')
    indentation_level = len(path_tokens)
    list_prefix = indentation_level * 2 * ' ' + '* '
    file_basename = path_tokens[-1]
    if s3_name.endswith('/'):
        return list_prefix + file_basename
    else:
        bucket_url = "https://cimr-d.s3.amazonaws.com"
        return f"{list_prefix}[{file_basename}]({bucket_url}/{s3_name})"

def create_folders(curr_folders, prev_folders):
    """This function compares curr_folders with prev_folders,
    and generates all folders that are not in prev_folders.
    """
    idx = 0
    end = min(len(curr_folders), len(prev_folders))
    while idx < end:
        if curr_folders[idx] != prev_folders[idx]:
            break
        idx += 1

    if idx == len(curr_folders):
        return

    while idx < len(curr_folders):
        s3_folder_path = '/'.join(curr_folders[0:(idx + 1)]) + '/'
        md_name = get_md_name(s3_folder_path)
        file_out.write(md_name + '\n')
        idx += 1


with open(TXT_FILENAME) as file_in, open(MD_FILENAME, 'w') as file_out:
    file_out.write("List of processed files (with links to AWS S3 bucket):\n")
    file_out.write("----\n")

    prev_folders = []
    for line_in in file_in:
        tokens = line_in.split()
        s3_name = " ".join(tokens[4:])
        md_name = get_md_name(s3_name)

        if s3_name.endswith('/'):
            curr_folders = s3_name.split('/')[0:-2]
            create_folders(curr_folders, prev_folders)
            # Do not show size and date fields for a directory
            file_out.write(md_name + '\n')
        else:
            curr_folders = s3_name.split('/')[0:-1]
            create_folders(curr_folders, prev_folders)
            # For a regular file, includes size and date fields too
            s3_date = tokens[0] + " " + tokens[1]
            s3_size = tokens[2] + " " + tokens[3]
            date_str = f" (updated on *{s3_date}*)"
            size_str = ": " + s3_size
            file_out.write(md_name + size_str + date_str + '\n')

        prev_folders = s3_name.split('/')[0:-1]
