import torch
import torch.nn as nn
import numpy as np
import librosa

class StutterCNN(nn.Module):
    def __init__(self):
        super(StutterCNN, self).__init__()
        self.conv1 = nn.Conv2d(1, 32, kernel_size=3, stride=1, padding=1)
        self.pool = nn.MaxPool2d(kernel_size=2, stride=2, padding=0)
        self.conv2 = nn.Conv2d(32, 64, kernel_size=3, stride=1, padding=1)
        self.fc1 = nn.Linear(64*32*25, 128)  # Adjust based on new input shape
        self.dropout = nn.Dropout(0.3)
        self.fc2 = nn.Linear(128, 2)

    def forward(self, x):
        x = self.pool(torch.relu(self.conv1(x)))
        #print(x.shape)
        x = self.pool(torch.relu(self.conv2(x)))
        #print(x.shape)
        x = x.view(x.size(0), -1)
        #print(x.shape)
        x = torch.relu(self.fc1(x))
        #print(x.shape)
        x = self.dropout(x)
        #print(x.shape)
        x = self.fc2(x)
        return x
    
    def extract_features(self, file_path, max_pad_length=100):
        y, sr = librosa.load(file_path, sr=16000)
        if len(y) == 0:
            #print(f"Warning: {file_path} is empty. Skipping.")
            return None
        
        mel_spec = librosa.feature.melspectrogram(y=y, sr=sr)
        mel_spec_db = librosa.power_to_db(mel_spec, ref=np.max)
            
        zcr = librosa.feature.zero_crossing_rate(y)  # Detects blocking

        spectral_flatness = librosa.feature.spectral_flatness(y=y)  # Detects prolongation

        rms = librosa.feature.rms(y=y)
        
        features = np.vstack([mel_spec_db, zcr, spectral_flatness, rms])
        if features.shape[1] > max_pad_length:
            features = features[:, :max_pad_length]
        else:
            pad_width = max_pad_length - features.shape[1]
            features = np.pad(features, ((0, 0), (0, pad_width)), mode='constant') 
        return torch.tensor(features, dtype=torch.float32).unsqueeze(0)
    

