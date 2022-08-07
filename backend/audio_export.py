from glob import glob

from pydub import AudioSegment

if __name__ == '__main__':
    files = glob('music_room/music/*.flac')
    for file in files:
        flac_audio = AudioSegment.from_file(file, 'flac')
        flac_audio.export(file.replace('.flac', '.mp3'), format='mp3')
