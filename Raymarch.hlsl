

void raymarchv1_float(float3 rayOrigin,  float3 rayDir, float nSteps, float stepSize,
    float densityScale, float4 sphere, out float result)
{
    float density = 0;

    for (int i = 0; i < nSteps; i ++)
    {
        //Calculate density
        float sphereDist = distance(rayOrigin, sphere.xyz);

        if (sphereDist < sphere.w)
        {
            density += 0.1;
        }
    }
    result = density * densityScale;
}

void raymarchv2_float(float3 rayOrigin,  float3 rayDir, float nSteps, float stepSize,
    float densityScale,UnityTexture3D volumeTex, UnitySamplerState volumeSampler, float3 offset, out float result)
{
    float density = 0;
    float transmission = 0;

    for (int i = 0; i < nSteps; i ++)
    {
        rayOrigin += (rayDir * stepSize);
        
        //Calculate density
        float sampledDensity = SAMPLE_TEXTURE3D(volumeTex, volumeSampler, rayOrigin + offset).r;
        density += sampledDensity;
    }
    
    result = density * densityScale;
}

void raymarch_float(float3 rayOrigin,  float3 rayDir, float nSteps, float stepSize,
    float densityScale,UnityTexture3D volumeTex, UnitySamplerState volumeSampler, float3 offset
    , float numLightSteps, float lightStepSize, float3 lightDir, float lightAbsorb, float darknessThreshold, float transmittance
    , out float3 result)
{
    float density = 0;
    float transmission = 0;
    float lightAccumlation = 0;
    float finalLight = 0;

    for (int i = 0; i < nSteps; i ++)
    {
        rayOrigin += (rayDir * stepSize);

        // the blue dot position
        float3 samplePos = rayOrigin + offset;
        float sampledDensity = SAMPLE_TEXTURE3D(volumeTex, volumeSampler, samplePos).r;
        
        
        //Calculate density
        density += sampledDensity * densityScale;

        // light loop
        float3 lightRayOrigin = samplePos;

        for (int j = 0; j < numLightSteps; j++)
        {
            // the red dot position
            lightRayOrigin += -lightDir * lightStepSize;
            float lightDensity = SAMPLE_TEXTURE3D(volumeTex, volumeSampler, lightRayOrigin).r;

            // the accumulated density from samplePos to the light - the higher this value the less light reaches samplePos
            lightAccumlation += lightDensity;
        }
        // the amount of light recieved along the ray from param rayOrigin in the direction rayDirection
        float lightTransmission = exp(-lightAccumlation);

        // shadow tends to the darkness threshold as lightAccumilation rises
        float shadow = darknessThreshold + lightTransmission * (1.0 - darknessThreshold);

        // the final light value is accumlated based on the current density, transmittance value and the calulated shadow value
        finalLight += density * transmittance * shadow;

        // initially a param its value is updated at each step by lightAbsorb, this sets the light lost by scattering
        transmittance *= exp(-density * lightAbsorb);
    }
    transmission = exp(-density);
    
    result = float3(finalLight, transmission, transmittance);
}