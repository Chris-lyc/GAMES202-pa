#include "denoiser.h"

Denoiser::Denoiser() : m_useTemportal(false) {}

void Denoiser::Reprojection(const FrameInfo &frameInfo) {
    int height = m_accColor.m_height;
    int width = m_accColor.m_width;
    Matrix4x4 preWorldToScreen =
        m_preFrameInfo.m_matrix[m_preFrameInfo.m_matrix.size() - 1];
    Matrix4x4 preWorldToCamera =
        m_preFrameInfo.m_matrix[m_preFrameInfo.m_matrix.size() - 2];
#pragma omp parallel for
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            // TODO: Reproject
            m_valid(x, y) = false;
            m_misc(x, y) = Float3(0.f);

            auto Position=frameInfo.m_position(x,y);
            auto Id=frameInfo.m_id(x,y);
            if(Id==-1)continue;

            auto objectToWorld=frameInfo.m_matrix[Id];
            auto preObjectToWorld=m_preFrameInfo.m_matrix[Id];
            
            auto preScreenPosition=preWorldToScreen(preObjectToWorld((Inverse(objectToWorld))(Position, Float3::EType::Point),Float3::EType::Point),Float3::EType::Point);
            auto preId=m_preFrameInfo.m_id(preScreenPosition.x,preScreenPosition.y);

            if(preScreenPosition.x>=0&&preScreenPosition.x<width&&preScreenPosition.y>=0&&preScreenPosition.y<height && preId==Id)
            {
                m_valid(x,y)=true;
                m_misc(x,y)=m_accColor(preScreenPosition.x,preScreenPosition.y);
            }
        }
    }
    std::swap(m_misc, m_accColor);
}

void Denoiser::TemporalAccumulation(const Buffer2D<Float3> &curFilteredColor) {
    int height = m_accColor.m_height;
    int width = m_accColor.m_width;
    int kernelRadius = 3;
#pragma omp parallel for
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            // TODO: Temporal clamp
            //// m_acc为前一帧 curFilteredColor为当前帧
            Float3 color = m_accColor(x, y);

            Float3 mean(0.0),sigma(0.0);
            int x_left=std::max(0,x-kernelRadius);
            int x_right=std::min(width-1,x+kernelRadius);
            int y_left=std::max(0,y-kernelRadius);
            int y_right=std::min(height-1,y+kernelRadius); 
            for(int i=x_left;i<=x_right;i++)
            {
                for(int j=y_left;j<=y_right;j++)
                {
                    mean+=curFilteredColor(i,j);
                }
            }
            mean/=Sqr(2*kernelRadius+1);
            for(int i=x_left;i<=x_right;i++)
            {
                for(int j=y_left;j<=y_right;j++)
                {
                    sigma+=Sqr(curFilteredColor(i,j)-mean);
                }
            }
            sigma/=Sqr(2*kernelRadius+1);

            //// 将上一帧clamp到当前帧附近
            float k=m_colorBoxK;
            color=Clamp(color,mean-sigma*k,mean+sigma*k);

            // TODO: Exponential moving average
            float alpha = 1.0f;

            if(m_valid(x,y))
                alpha=m_alpha;
            m_misc(x, y) = Lerp(color, curFilteredColor(x, y), alpha);
        }
    }
    std::swap(m_misc, m_accColor);
}

Buffer2D<Float3> Denoiser::Filter(const FrameInfo &frameInfo) {
    int height = frameInfo.m_beauty.m_height;
    int width = frameInfo.m_beauty.m_width;
    Buffer2D<Float3> filteredImage = CreateBuffer2D<Float3>(width, height);
    int kernelRadius = 16;
#pragma omp parallel for
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            // TODO: Joint bilateral filter
            filteredImage(x, y) = frameInfo.m_beauty(x, y);
            
            auto color_i = frameInfo.m_beauty(x,y);
            auto normal_i = frameInfo.m_normal(x,y);
            auto position_i = frameInfo.m_position(x,y);
            float sum_of_weights = 0.0f;
            Float3 sum_of_weighted_values(0.0);
            int x_left=std::max(0,x-kernelRadius);
            int x_right=std::min(width-1,x+kernelRadius);
            int y_left=std::max(0,y-kernelRadius);
            int y_right=std::min(height-1,y+kernelRadius);

            for(int x_j=x_left;x_j<=x_right;x_j++)
            {
                for(int y_j=y_left;y_j<=y_right;y_j++)
                {
                    if(x_j==x&&y_j==y)
                    {
                        sum_of_weights+=1.0f;
                        sum_of_weighted_values+=color_i;
                        continue;
                    }

                    auto color_j = frameInfo.m_beauty(x_j,y_j);
                    auto normal_j = frameInfo.m_normal(x_j,y_j);
                    auto position_j = frameInfo.m_position(x_j,y_j);

                    auto d_normal = SafeAcos(Dot(normal_i,normal_j));
                    auto ij_length=Length(position_j - position_i);
                    float d_plane=0.0;
                    if(ij_length!=0.0)
                    {
                        d_plane = Dot(normal_i,(position_j - position_i)) / ij_length;
                    }
                    auto term1 = - (pow(x_j - x,2.0) + pow(y_j - y,2.0)) / (2.0f * pow(m_sigmaCoord,2.0));
                    auto term2 = - (SqrLength(color_i - color_j) / (2.0f * pow(m_sigmaColor,2.0)));
                    auto term3 = - (pow(d_normal,2.0) / (2.0f * pow(m_sigmaNormal,2.0)));
                    auto term4 = - (pow(d_plane,2.0) / (2.0f * pow(m_sigmaPlane,2.0)));
                    auto J = exp(term1+term2+term3+term4);
                    sum_of_weights+=J;
                    sum_of_weighted_values+=color_j*J;
                }
            }
            filteredImage(x,y)=sum_of_weighted_values/sum_of_weights;
        }
    }
    return filteredImage;
}

void Denoiser::Init(const FrameInfo &frameInfo, const Buffer2D<Float3> &filteredColor) {
    m_accColor.Copy(filteredColor);
    int height = m_accColor.m_height;
    int width = m_accColor.m_width;
    m_misc = CreateBuffer2D<Float3>(width, height);
    m_valid = CreateBuffer2D<bool>(width, height);
}

void Denoiser::Maintain(const FrameInfo &frameInfo) { m_preFrameInfo = frameInfo; }

Buffer2D<Float3> Denoiser::ProcessFrame(const FrameInfo &frameInfo) {
    // Filter current frame
    Buffer2D<Float3> filteredColor;
    filteredColor = Filter(frameInfo);

    // Reproject previous frame color to current
    if (m_useTemportal) {
        Reprojection(frameInfo);
        TemporalAccumulation(filteredColor);
    } else {
        Init(frameInfo, filteredColor);
    }

    // Maintain
    Maintain(frameInfo);
    if (!m_useTemportal) {
        m_useTemportal = true;
    }
    return m_accColor;
}
