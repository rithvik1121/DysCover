import torch
import torch.nn as nn

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