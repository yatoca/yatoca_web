import React from 'react';
import './AllOrgsPopUp.css';
import SafeArea from '@/components/basic/safe-area';
import { CloseTwoSVG } from '@/constants/svgs';
import { companies } from '@/constants';

type Props = {
    close: () => void;
}
const AllOrgsPopUp: React.FC<Props> = ({ close }) => {
    return (
        <div className="all-orgs-popup-wrapper">
            <SafeArea>
                <>
                    <div className='w100 d-flex jce' onClick={close}><div className='pointer'><CloseTwoSVG /></div></div>
                    <div className="orgs-grid">
                        {companies.map((company, index) => (
                            <div key={index} className="orgs-grid-item uppercase thunder-fw-bold-lc">{company.name_company}</div>
                        ))}
                    </div>
                </>
            </SafeArea>
        </div>
    );
};

export default AllOrgsPopUp;